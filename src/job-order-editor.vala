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

public class Mpcjo.JobOrderEditor : StackPage {

    public bool editable { public get; private set; }
    public Database database { public get; private set; }

    private int jo_id;
    private int customer_id;
    private int po_id;

    private SpinButton spinbutton_jo_refnum;
    private Entry entry_jo_desc;
    private ComboBox combobox_jo_customer;
    private Entry entry_jo_customer;
    private EntryCompletion entrycompletion_jo_customer;
    private Entry entry_jo_address;
    private DateEntry entry_jo_date_start;
    private DateEntry entry_jo_date_end;
    private Button button_jo_purchase_order;

    private CellAreaBox cellareabox_jo_customer;
    private CellRendererText cellrenderertext_name;
    private CellRendererText cellrenderertext_address;

    private ListStore customers;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/job-order-editor.ui");
            builder.connect_signals (this);

            var scrolledwindow = builder.get_object ("scrolledwindow") as ScrolledWindow;
            add (scrolledwindow);

            can_focus = true;

            spinbutton_jo_refnum = builder.get_object ("spinbutton_jo_refnum") as SpinButton;
            entry_jo_desc = builder.get_object ("entry_jo_desc") as Entry;
            combobox_jo_customer = builder.get_object ("combobox_jo_customer") as ComboBox;
            entry_jo_customer = builder.get_object ("entry_jo_customer") as Entry;
            entrycompletion_jo_customer = builder.get_object ("entrycompletion_jo_customer") as EntryCompletion;
            entry_jo_address = builder.get_object ("entry_jo_address") as Entry;
            entry_jo_date_start = builder.get_object ("entry_jo_date_start") as DateEntry;
            entry_jo_date_end = builder.get_object ("entry_jo_date_end") as DateEntry;
            button_jo_purchase_order = builder.get_object ("button_jo_purchase_order") as Button;

            cellareabox_jo_customer = builder.get_object ("cellareabox_jo_customer") as CellAreaBox;
            cellrenderertext_name = builder.get_object ("cellrenderertext_name") as CellRendererText;
            cellrenderertext_address = builder.get_object ("cellrenderertext_address") as CellRendererText;
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public JobOrderEditor (Database database) {
        this.database = database;
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
        lock (jo_id) {
            jo_id = 0;
        }

        spinbutton_jo_refnum.value = 0;
        entry_jo_desc.text = "";
        entry_jo_customer.text = "";
        entry_jo_address.text = "";
        entry_jo_date_start.entry.text = "";
        entry_jo_date_end.entry.text = "";
        button_jo_purchase_order.label = _("None");

        customers = database.create_customers_list ();
        yield database.load_customers_to_model (customers);

        entrycompletion_jo_customer.model = customers;
        entrycompletion_jo_customer.text_column = Database.CustomersListColumns.NAME;

        combobox_jo_customer.model = customers;
        combobox_jo_customer.entry_text_column = Database.CustomersListColumns.NAME;

        /* Hide renderers created by entry completion and combo box */
        cellareabox_jo_customer.foreach ((renderer) => {
            if (renderer != cellrenderertext_name &&
                renderer != cellrenderertext_address) {
                renderer.visible = false;
            }

            return false;
        });
    }

    public async void create_new () throws Error {
        yield initialize ();
    }

    public async bool edit (int id) throws Error {
        SourceFunc callback = edit.callback;

        /* FIXME: Show loading indicator */
        yield initialize ();

        debug ("Loading job order to edit");

        ThreadFunc<Error?> run = () => {
            DataModel dm = null;

            database.cnc.lock ();

            try {
                Gda.Set stmt_params;
                Value value_id = id;

                var stmt = database.cnc.
                    parse_sql_string ("SELECT" +
                                      " job_orders.id, job_orders.ref_number," +
                                      " description," +
                                      " customers.id, customers.name, job_orders.address," +
                                      " date_start, date_end," +
                                      " purchase_orders.id, purchase_orders.ref_number " +
                                      "FROM job_orders " +
                                      "LEFT JOIN customers ON (job_orders.customer = customers.id) " +
                                      "LEFT JOIN purchase_orders ON (job_orders.purchase_order = purchase_orders.id) " +
                                      "WHERE job_orders.id=##id::int",
                                      out stmt_params);

                stmt_params.get_holder ("id").set_value (value_id);
                dm = database.cnc.statement_execute_select (stmt, stmt_params);
            } catch (Error e) {
                warning ("Failed to get job orders: %s", e.message);

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

                lock (jo_id) {
                    jo_id = (int) iter.get_value_at (0);
                }

                var jo_number = (int) iter.get_value_at (1);

                column = iter.get_value_at (2);
                var description = database.dh_string.get_str_from_value (column);

                lock (customer_id) {
                    customer_id = (int) iter.get_value_at (3);
                }

                column = iter.get_value_at (4);
                var customer = database.dh_string.get_str_from_value (column);

                column = iter.get_value_at (5);
                var address = database.dh_string.get_str_from_value (column);

                column = iter.get_value_at (6);
                date = Date ();
                date.set_parse (database.dh_string.get_str_from_value (column));

                var date_start = "";
                if (date.valid ()) {
                    date.strftime (s, "%a, %d %b, %Y");
                    date_start = ((string) s).dup ();
                }

                column = iter.get_value_at (7);
                date = Date ();
                date.set_parse (database.dh_string.get_str_from_value (column));

                var date_end = "";
                if (date.valid ()) {
                    date.strftime (s, "%a, %d %b, %Y");
                    date_end = ((string) s).dup ();
                }

                column = iter.get_value_at (8);
                lock (po_id) {
                    po_id = (!column.holds (typeof (Null))?
                             (int) column : 0);
                }

                var po_number = (int) iter.get_value_at (9);

                Idle.add (() => {
                    spinbutton_jo_refnum.value = jo_number;
                    entry_jo_desc.text = description;
                    entry_jo_customer.text = customer;
                    entry_jo_address.text = address;
                    entry_jo_date_start.entry.text = date_start;
                    entry_jo_date_end.entry.text = date_end;
                    button_jo_purchase_order.label = _("P.O. #%d").printf (po_number);

                    debug ("Finished loading of job order data");

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
        var thread = new Thread<Error?> ("joe_e", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

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

                lock (jo_id) {
                    if (jo_id > 0) {
                        yield update_job_order ();
                    } else {
                        jo_id = yield create_job_order ();
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
                warning ("Failed to insert job order: %s", e.message);

                return false;
            }
        } catch (Error e) {
            /* FIXME: Throw errors here */
            warning ("Failed to save job order: %s", e.message);

            return false;
        }

        return true;
    }

    public async int create_job_order () throws Error {
        int ret = 0;

        int customer_id_exists = yield database.get_customer_id (entry_jo_customer.text);
        lock (customer_id) {
            if (customer_id_exists > 0) {
                customer_id = customer_id_exists;
            } else {
                customer_id = yield database.create_customer (entry_jo_customer.text,
                                                              entry_jo_address.text);
            }
        }

        lock (customer_id) {
            lock (po_id) {
                ret = yield database.create_job_order ((int) spinbutton_jo_refnum.value,
                                                       customer_id,
                                                       entry_jo_desc.text,
                                                       entry_jo_address.text,
                                                       entry_jo_date_start.entry.text,
                                                       entry_jo_date_end.entry.text,
                                                       po_id);
            }
        }

        return ret;
    }

    public async bool update_job_order () throws Error {
        bool ret = false;

        int customer_id_exists = yield database.get_customer_id (entry_jo_customer.text);
        lock (customer_id) {
            if (customer_id_exists > 0) {
                customer_id = customer_id_exists;
            } else {
                customer_id = yield database.create_customer (entry_jo_customer.text,
                                                              entry_jo_address.text);
            }
        }

        lock (jo_id) {
            lock (customer_id) {
                lock (po_id) {
                    ret = yield database.update_job_order (jo_id,
                                                           (int) spinbutton_jo_refnum.value,
                                                           customer_id,
                                                           entry_jo_desc.text,
                                                           entry_jo_address.text,
                                                           entry_jo_date_start.entry.text,
                                                           entry_jo_date_end.entry.text,
                                                           po_id);
                }
            }
        }

        return ret;
    }

    public async bool remove_job_order () throws Error {
        bool ret = false;

        lock (jo_id) {
            ret = yield database.remove_job_order (jo_id);
        }

        return ret;
    }

    public async int create_customer () throws Error {
        return yield database.create_customer (entry_jo_customer.text,
                                               entry_jo_address.text);
    }

    [CCode (instance_pos = -1)]
    public void on_combobox_jo_customer_changed (ComboBox combo_box) {
        TreeIter iter;

        if (combobox_jo_customer.get_active_iter (out iter)) {
            string address;

            customers.get (iter,
                           Database.CustomersListColumns.ADDRESS, out address);
            entry_jo_address.text = address;
        }
    }

    [CCode (instance_pos = -1)]
    public void on_button_jo_purchase_order_clicked (Button button) {
        var listview = new PurchaseOrderListView (database);
        listview.closed.connect (() => {
            lock (po_id) {
                int po_number;

                po_id = listview.get_selected_item (out po_number);
                button_jo_purchase_order.label = _("P.O. #%d").printf (po_number);
            }
        });
        listview.show ();
        stack.push (listview);
    }

}

public errordomain JobOrderEditorError {
    ENTRY_MISSING,
    INVALID_FIELD
}
