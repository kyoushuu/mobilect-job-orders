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

public class Mpcjo.InvoiceListView : View {

    public Database database { public get; private set; }

    public struct Item {
        public int id;
        public int ref_num;
    }

    public signal void invoice_selected (int id);

    public virtual signal void add_activated (Item[] items) {
    }

    private InvoiceEditor invoiceeditor;
    private Button button_add;

    private TreeViewColumn treeviewcolumn_invoice;
    private CellRendererText cellrenderertext_invoice_number;
    private TreeViewColumn treeviewcolumn_date;
    private CellRendererText cellrenderertext_date;
    private TreeViewColumn treeviewcolumn_payment_date;
    private CellRendererText cellrenderertext_payment_date;
    private TreeViewColumn treeviewcolumn_remarks;
    private CellRendererText cellrenderertext_remarks;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/invoice-list-view.ui");
            builder.connect_signals (this);

            button_add = builder.get_object ("button_add") as Button;
            toolbar_selection.pack_end (button_add);

            treeviewcolumn_invoice = builder.get_object ("treeviewcolumn_invoice") as TreeViewColumn;
            cellrenderertext_invoice_number = builder.get_object ("cellrenderertext_invoice_number") as CellRendererText;
            treeview.append_column (treeviewcolumn_invoice);

            treeviewcolumn_date = builder.get_object ("treeviewcolumn_date") as TreeViewColumn;
            cellrenderertext_date = builder.get_object ("cellrenderertext_date") as CellRendererText;
            treeview.append_column (treeviewcolumn_date);

            treeviewcolumn_payment_date = builder.get_object ("treeviewcolumn_payment_date") as TreeViewColumn;
            cellrenderertext_payment_date = builder.get_object ("cellrenderertext_payment_date") as CellRendererText;
            treeview.append_column (treeviewcolumn_payment_date);

            treeviewcolumn_remarks = builder.get_object ("treeviewcolumn_remarks") as TreeViewColumn;
            cellrenderertext_remarks = builder.get_object ("cellrenderertext_remarks") as CellRendererText;
            treeview.append_column (treeviewcolumn_remarks);

            treeviewcolumn_invoice.set_cell_data_func (cellrenderertext_invoice_number, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                int refnum;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.InvoicesListColumns.REF_NUM, out refnum);

                if (refnum > 0) {
                    cellrenderertext_invoice_number.markup = "Invoice #%d".printf (refnum);
                } else {
                    cellrenderertext_invoice_number.markup = null;
                }
            });

            treeviewcolumn_date.set_cell_data_func (cellrenderertext_date, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                string date_string;
                var date = Date ();
                char s[64];

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.InvoicesListColumns.DATE, out date_string);

                if (date_string != null && date_string != "") {
                    date.set_parse (date_string);
                    date.strftime (s, "%a, %d %b, %Y");
                    cellrenderertext_date.markup = (string) s;
                } else {
                    cellrenderertext_date.markup = null;
                }
            });

            treeviewcolumn_payment_date.set_cell_data_func (cellrenderertext_payment_date, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                string date_string;
                var date = Date ();
                char s[64];

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.InvoicesListColumns.PAYMENT_DATE, out date_string);

                if (date_string != null && date_string != "") {
                    date.set_parse (date_string);
                    date.strftime (s, "Paid %a, %d %b, %Y");
                    cellrenderertext_payment_date.markup = (string) s;
                } else {
                    cellrenderertext_payment_date.markup = null;
                }
            });
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public InvoiceListView (Database database) {
        this.database = database;
        /* Load invoices */
        load_invoices.begin ((obj, res) => {
        });
    }

    public override void new_activated () {
        create_editor ();
        invoiceeditor.create_new.begin ((obj, res) => {
            base.new_activated ();
        });
    }

    public override void delete_activated () {
        int id;
        var items = new int[0];

        foreach (var iter in get_selected_iters ()) {
            list.get (iter, Database.InvoicesListColumns.ID, out id);
            items += id;
        }

        delete_invoices.begin (items, (obj, res) => {
            base.delete_activated ();
        });
    }

    public override void item_activated (TreeIter iter) {
        int id;
        list.get (iter, Database.InvoicesListColumns.ID, out id);

        create_editor ();
        invoiceeditor.edit.begin (id);
        invoice_selected (id);
    }

    public async void load_invoices () {
        debug ("Request loading of invoices");

        list = database.create_invoices_list ();
        database.load_invoices_to_model.begin (list);

        debug ("Request to load invoices succeeded");
    }

    private async void delete_invoices (int[] items) {
        try {
            database.cnc.lock ();
            database.cnc.begin_transaction (null, TransactionIsolation.REPEATABLE_READ);
            database.cnc.unlock ();

            try {
                foreach (var id in items) {
                    yield database.remove_invoice (id);
                }

                database.cnc.lock ();
                database.cnc.commit_transaction (null);
                database.cnc.unlock ();
            } catch (Error e) {
                database.cnc.lock ();
                database.cnc.rollback_transaction (null);
                database.cnc.unlock ();

                /* FIXME: Throw errors here */
                warning ("Failed to delete invoice: %s", e.message);
            }
        } catch (Error e) {
            /* FIXME: Throw errors here */
            warning ("Failed to delete invoices: %s", e.message);
        }
    }

    private void create_editor () {
        invoiceeditor = new InvoiceEditor (database);
        invoiceeditor.closed.connect (() => {
            /* FIXME: Lessen loading here */
            load_invoices.begin ((obj, res) => {
                load_invoices.end (res);
            });
        });
        invoiceeditor.show ();
        stack.push (invoiceeditor);
    }

    [CCode (instance_pos = -1)]
    public void on_button_add_clicked (Button button) {
        var items = new Item[0];

        if (list == null)
            return;

        list.foreach ((model, path, iter) => {
            int id, ref_num;
            bool selected;

            list.get (iter,
                      Database.InvoicesListColumns.ID, out id,
                      Database.InvoicesListColumns.REF_NUM, out ref_num,
                      View.ModelColumns.SELECTED, out selected);

            if (selected) {
                var item = Item() {
                    id = id,
                    ref_num = ref_num
                };
                items += item;
            }

            return false;
        });

        add_activated (items);
    }

}
