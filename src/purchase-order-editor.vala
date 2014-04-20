/*
 * Copyright (c) 2013 Mobilect Power Corp.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author: Arnel A. Borja <kyoushuu@yahoo.com>
 *
 */

using Gtk;
using Gda;
using Mpcw;

public class Mpcjo.PurchaseOrderEditor : StackPage {

    public bool editable { public get; private set; }
    public Database database { public get; private set; }

    private int po_id;
    private List<int> invoices;

    private SpinButton spinbutton_po_refnum;
    private DateEntry entry_po_date;
    private ListBox listbox_po_invoices;
    private ToolButton toolbutton_in_remove;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/purchase-order-editor.ui");
            builder.connect_signals (this);

            var grid = builder.get_object ("grid") as Grid;
            add (grid);

            can_focus = true;

            spinbutton_po_refnum = builder.get_object ("spinbutton_po_refnum") as SpinButton;
            entry_po_date = builder.get_object ("entry_po_date") as DateEntry;
            listbox_po_invoices = builder.get_object ("listbox_po_invoices") as ListBox;
            toolbutton_in_remove = builder.get_object ("toolbutton_in_remove") as ToolButton;
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public PurchaseOrderEditor (Database database) {
        this.database = database;
    }

    public override void shown () {
        stack.headerbar.title = _("Purchase Order #%d").printf ((int) spinbutton_po_refnum.value);
        base.shown ();
    }

    public override void hidden () {
        stack.headerbar.title = null;
        base.hidden ();
    }

    public override void close () {
        save.begin ((obj, res) => {
            if (save.end (res)) {
                base.close ();
            }
        });
    }

    private bool check_fields () {
        if (database == null) {
            return false;
        }

        /* NOTE: Should lock/unlock cnc per statement */
        /* FIXME: Check if customer exists (ask user if not) */
        /* FIXME: Create customer if doesn't exists */

        return true;
    }

    private async void initialize () throws Error {
        lock (po_id) {
            po_id = 0;
        }

        spinbutton_po_refnum.value = 0;
        entry_po_date.entry.text = "";
    }

    public async void create_new () throws Error {
        yield initialize ();
    }

    public async bool edit (int id) throws Error {
        SourceFunc callback = edit.callback;

        /* FIXME: Show loading indicator */
        yield initialize ();

        debug ("Loading purchase order to edit");

        ThreadFunc<Error?> run = () => {
            DataModel dm = null;

            database.cnc.lock ();

            try {
                Gda.Set stmt_params;
                Value value_id = id;

                var stmt = database.cnc.
                    parse_sql_string ("SELECT" +
                                      " ref_number, date " +
                                      "FROM purchase_orders " +
                                      "WHERE id=##id::int",
                                      out stmt_params);

                stmt_params.get_holder ("id").set_value (value_id);
                dm = database.cnc.statement_execute_select (stmt, stmt_params);
            } catch (Error e) {
                warning ("Failed to get purchase orders: %s", e.message);

                Idle.add((owned) callback);
                return e;
            } finally {
                database.cnc.unlock ();
            }

            if (dm == null || dm.get_n_rows () != 1) {
                /* FIXME: Throw an error here */
                Idle.add((owned) callback);
                return null;
            }

            var iter = dm.create_iter ();
            if (iter.move_next ()) {
                Value? column;
                Date date;
                char s[64];

                lock (po_id) {
                    po_id = id;
                }

                column = iter.get_value_at (0);
                var po_number = (!column.holds (typeof (Null))?
                                 (int) column : 0);

                column = iter.get_value_at (1);
                date = Date ();
                date.set_parse (database.dh_string.get_str_from_value (column));

                var date_po = "";
                if (date.valid ()) {
                    date.strftime (s, "%a, %d %b, %Y");
                    date_po = ((string) s).dup ();
                }

                Idle.add (() => {
                    lock (po_id) {
                        entry_po_date.entry.sensitive = (po_id > 0);
                    }
                    spinbutton_po_refnum.value = po_number;
                    entry_po_date.entry.text = date_po;

                    debug ("Finished loading of purchase order data");

                    return false;
                });

                Idle.add((owned) callback);
                return null;
            } else {
                /* FIXME: Throw an error here */
                Idle.add((owned) callback);
                return null;
            }
        };
        var thread = new Thread<Error?> ("poe_e", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        var list = database.create_mappings_list ();
        database.load_mappings_to_model.begin (list, null, (obj, res) => {
            list.foreach ((m, p, iter) => {
                int po_id, in_id, in_number;
                list.get (iter,
                          Database.MappingsListColumns.PURCHASE_ORDER_ID, out po_id,
                          Database.MappingsListColumns.INVOICE_ID, out in_id,
                          Database.MappingsListColumns.INVOICE_REF_NUM, out in_number);

                if (po_id == id && invoices.find (in_id) == null) {
                    add_invoice_row (in_id, in_number);
                }

                return false;
            });
        });

        return true;
    }

    public async bool save () {
        if (!check_fields ()) {
            return false;
        }

        try {
            database.cnc.lock ();
            database.cnc.begin_transaction (null, TransactionIsolation.REPEATABLE_READ);
            database.cnc.unlock ();

            try {
                /* FIXME: Check if reference number exists and id do not match (error for duplicates) */

                lock (po_id) {
                    if (po_id > 0) {
                        yield update_purchase_order ();
                    } else {
                        po_id = yield create_purchase_order ();
                    }
                }

                database.cnc.lock ();
                database.cnc.commit_transaction (null);
                database.cnc.unlock ();
            } catch (Error e) {
                database.cnc.lock ();
                database.cnc.rollback_transaction (null);
                database.cnc.unlock ();

                /* FIXME: Throw errors here */
                warning ("Failed to insert purchase order: %s", e.message);

                return false;
            }
        } catch (Error e) {
            /* FIXME: Throw errors here */
            warning ("Failed to save purchase order: %s", e.message);

            return false;
        }

        return true;
    }

    public async int create_purchase_order () throws Error {
        int ret = 0;

        ret = yield database.create_purchase_order ((int) spinbutton_po_refnum.value,
                                                    entry_po_date.entry.text);

        return ret;
    }

    public async bool update_purchase_order () throws Error {
        bool ret = false;

        lock (po_id) {
            ret = yield database.update_purchase_order (po_id,
                                                        (int) spinbutton_po_refnum.value,
                                                        entry_po_date.entry.text);
        }

        return ret;
    }

    public async bool remove_purchase_order () throws Error {
        bool ret = false;

        lock (po_id) {
            ret = yield database.remove_purchase_order (po_id);
        }

        return ret;
    }

    private void add_invoice_row (int id, int refnum) {
        var row = new ListBoxRow ();
        row.set_data ("in_id", id);
        listbox_po_invoices.add (row);
        row.show ();

        var label = new Label (_("Invoice #%d").printf (refnum));
        label.set_alignment (0.0f, 0.5f);
        label.set_margin_left (20);
        label.set_margin_right (20);
        label.set_margin_top (6);
        label.set_margin_bottom (6);
        row.add (label);
        label.show ();

        invoices.append (id);
    }

    [CCode (instance_pos = -1)]
    public void on_spinbutton_po_refnum_value_changed (SpinButton spinbutton) {
        stack.headerbar.title = _("Purchase Order #%d").printf ((int) spinbutton_po_refnum.value);
    }

    [CCode (instance_pos = -1)]
    public void toolbutton_in_add_clicked (ToolButton toolbutton) {
        var listview = new InvoiceListView (database);
        listview.add_activated.connect ((items) => {
            foreach (var item in items) {
                if (invoices.find (item.id) == null) {
                    database.create_mapping.begin (po_id, item.id, (obj, res) => {
                        try {
                            if (database.create_mapping.end (res)) {
                                add_invoice_row (item.id, item.ref_num);
                            }
                        } catch (Error e) {
                            warning ("Failed to map invoice to purchase order: %s", e.message);
                        }
                    });
                }
            }
            stack.pop ();
        });
        listview.show ();
        stack.push (listview);
    }

    [CCode (instance_pos = -1)]
    public void toolbutton_in_remove_clicked (ToolButton toolbutton) {
        var row = listbox_po_invoices.get_selected_row ();
        var in_id = row.get_data<int> ("in_id");

        database.remove_mapping.begin (po_id, in_id, (obj, res) => {
            try {
                if (database.remove_mapping.end (res)) {
                    row.destroy ();
                    invoices.remove (in_id);
                }
            } catch (Error e) {
                warning ("Failed to unmap invoice to purchase order: %s", e.message);
            }
        });
    }

    [CCode (instance_pos = -1)]
    public void on_listbox_po_invoices_row_selected (ListBox list_box, ListBoxRow? row) {
        toolbutton_in_remove.sensitive = row != null;
    }

}
