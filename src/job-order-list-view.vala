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
using Gd;
using Mpcw;

public class Mpcjo.JobOrderListView : View {

    public Database database { public get; private set; }

    public signal void job_order_selected (int id);

    private JobOrderEditor jobordereditor;
    private HeaderSimpleButton button_print;

    private TreeViewColumn treeviewcolumn_job_order;
    private CellRendererText cellrenderertext_job_order_number;
    private TreeViewColumn treeviewcolumn_customer;
    private CellRendererText cellrenderertext_customer;
    private TreeViewColumn treeviewcolumn_date;
    private CellRendererText cellrenderertext_date;
    private TreeViewColumn treeviewcolumn_purchase_order;
    private CellRendererText cellrenderertext_purchase_order_number;
    private TreeViewColumn treeviewcolumn_invoice;
    private CellRendererText cellrenderertext_invoice_number;
    private TreeViewColumn treeviewcolumn_payment;
    private CellRendererText cellrenderertext_payment;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/job-order-list-view.ui");
            builder.connect_signals (this);

            button_print = builder.get_object ("button_print") as HeaderSimpleButton;
            toolbar_selection.pack_end (button_print);

            treeviewcolumn_job_order = builder.get_object ("treeviewcolumn_job_order") as TreeViewColumn;
            cellrenderertext_job_order_number = builder.get_object ("cellrenderertext_job_order_number") as CellRendererText;
            treeview.append_column (treeviewcolumn_job_order);

            treeviewcolumn_customer = builder.get_object ("treeviewcolumn_customer") as TreeViewColumn;
            cellrenderertext_customer = builder.get_object ("cellrenderertext_customer") as CellRendererText;
            treeview.append_column (treeviewcolumn_customer);

            treeviewcolumn_date = builder.get_object ("treeviewcolumn_date") as TreeViewColumn;
            cellrenderertext_date = builder.get_object ("cellrenderertext_date") as CellRendererText;
            treeview.append_column (treeviewcolumn_date);

            treeviewcolumn_purchase_order = builder.get_object ("treeviewcolumn_purchase_order") as TreeViewColumn;
            cellrenderertext_purchase_order_number = builder.get_object ("cellrenderertext_purchase_order_number") as CellRendererText;
            treeview.append_column (treeviewcolumn_purchase_order);

            treeviewcolumn_invoice = builder.get_object ("treeviewcolumn_invoice") as TreeViewColumn;
            cellrenderertext_invoice_number = builder.get_object ("cellrenderertext_invoice_number") as CellRendererText;
            treeview.append_column (treeviewcolumn_invoice);

            treeviewcolumn_payment = builder.get_object ("treeviewcolumn_payment") as TreeViewColumn;
            cellrenderertext_payment = builder.get_object ("cellrenderertext_payment") as CellRendererText;
            treeview.append_column (treeviewcolumn_payment);

            treeviewcolumn_job_order.set_cell_data_func (cellrenderertext_job_order_number, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                int refnum;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.JobOrdersListColumns.REF_NUM, out refnum);

                if (refnum > 0) {
                    cellrenderertext_job_order_number.markup = "J.O. #%d".printf (refnum);
                } else {
                    cellrenderertext_job_order_number.markup = null;
                }
            });

            treeviewcolumn_customer.set_cell_data_func (cellrenderertext_customer, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                string customer, description;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.JobOrdersListColumns.CUSTOMER, out customer);
                list.get (iter, Database.JobOrdersListColumns.DESCRIPTION, out description);

                cellrenderertext_customer.markup =
                    ("<span color=\"#000000000000\">%s</span>\n" +
                     "<span color=\"#88888a8a8585\">%s</span>")
                    .printf (customer, description);
            });

            treeviewcolumn_date.set_cell_data_func (cellrenderertext_date, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                string date_start, date_end, markup;
                var date = Date ();
                char s[64];

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.JobOrdersListColumns.DATE_START, out date_start);
                list.get (iter, Database.JobOrdersListColumns.DATE_END, out date_end);

                date.set_parse (date_start);
                date.strftime (s, "%a, %d %b, %Y");
                date_start = (string) s;

                date.set_parse (date_end);
                date.strftime (s, "%a, %d %b, %Y");
                date_end = (string) s;

                cellrenderertext_date.markup =
                    "<i>from</i> %s\n<i>to</i> %s"
                    .printf (date_start, date_end);
            });

            treeviewcolumn_purchase_order.set_cell_data_func (cellrenderertext_purchase_order_number, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                int id, refnum;
                string date_string;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.JobOrdersListColumns.PURCHASE_ORDER_ID, out id);
                list.get (iter, Database.JobOrdersListColumns.PURCHASE_ORDER_REF_NUM, out refnum);
                list.get (iter, Database.JobOrdersListColumns.PURCHASE_ORDER_DATE, out date_string);

                if (refnum > 0) {
                    var date = Date ();
                    char s[64];

                    date.set_parse (date_string);
                    date.strftime (s, "%a, %d %b, %Y");

                    cellrenderertext_purchase_order_number.markup =
                        ("<span color=\"#000000000000\">P.O. #%d</span>\n" +
                         "<span color=\"#88888a8a8585\">%s</span>")
                        .printf (refnum, (string) s);
                } else if (id > 0) {
                    cellrenderertext_purchase_order_number.markup =
                        ("<span color=\"#000000000000\">%s</span>\n")
                        .printf (_("Unreleased"));
                } else {
                    cellrenderertext_purchase_order_number.markup = null;
                }
            });

            treeviewcolumn_invoice.set_cell_data_func (cellrenderertext_invoice_number, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                int refnum;
                string date_string;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.JobOrdersListColumns.INVOICE_REF_NUM, out refnum);
                list.get (iter, Database.JobOrdersListColumns.INVOICE_DATE, out date_string);

                if (refnum > 0) {
                    var date = Date ();
                    char s[64];

                    date.set_parse (date_string);
                    date.strftime (s, "%a, %d %b, %Y");

                    cellrenderertext_invoice_number.markup =
                        ("<span color=\"#000000000000\">Invoice #%d</span>\n" +
                         "<span color=\"#88888a8a8585\">%s</span>")
                        .printf (refnum, (string) s);
                } else {
                    cellrenderertext_invoice_number.markup = null;
                }
            });

            treeviewcolumn_payment.set_cell_data_func (cellrenderertext_payment, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                string date_string;
                var date = Date ();
                char s[64];

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.JobOrdersListColumns.PAYMENT_DATE, out date_string);

                if (date_string != null && date_string != "") {
                    date.set_parse (date_string);
                    date.strftime (s, "%a, %d %b, %Y");
                    cellrenderertext_payment.markup =
                        ("<span color=\"#000000000000\">Paid</span>\n" +
                         "<span color=\"#88888a8a8585\">%s</span>")
                        .printf ((string) s);
                } else {
                    cellrenderertext_payment.markup = null;
                }
            });

            /* Print button is sensitive if there is a selected item */
            bind_property ("selected-items-num", button_print, "sensitive",
                           BindingFlags.SYNC_CREATE);
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public JobOrderListView (Database database) {
        this.database = database;
        /* Load job orders */
        load_job_orders.begin ((obj, res) => {
        });
    }

    public override void new_activated () {
        create_editor ();
        jobordereditor.create_new.begin ((obj, res) => {
            base.new_activated ();
        });
    }

    public override void delete_activated () {
        int id;
        var items = new int[0];

        foreach (var iter in get_selected_iters ()) {
            list.get (iter, Database.JobOrdersListColumns.ID, out id);
            items += id;
        }

        delete_job_orders.begin (items, (obj, res) => {
            base.delete_activated ();
        });
    }

    public override void item_activated (TreeIter iter) {
        int id;
        list.get (iter, Database.JobOrdersListColumns.ID, out id);

        create_editor ();
        jobordereditor.edit.begin (id);
        job_order_selected (id);
    }

    public async void load_job_orders () {
        debug ("Request loading of job orders");

        list = database.create_job_orders_list ();
        database.load_job_orders_to_model.begin (list);

        debug ("Request to load job orders succeeded");
    }

    private async void delete_job_orders (int[] items) {
        try {
            database.cnc.lock ();
            database.cnc.begin_transaction (null, TransactionIsolation.REPEATABLE_READ);
            database.cnc.unlock ();

            try {
                foreach (var id in items) {
                    yield database.remove_job_order (id);
                }

                database.cnc.lock ();
                database.cnc.commit_transaction (null);
                database.cnc.unlock ();
            } catch (Error e) {
                database.cnc.lock ();
                database.cnc.rollback_transaction (null);
                database.cnc.unlock ();

                /* FIXME: Throw errors here */
                warning ("Failed to delete job order: %s", e.message);
            }
        } catch (Error e) {
            /* FIXME: Throw errors here */
            warning ("Failed to delete job orders: %s", e.message);
        }
    }

    private void create_editor () {
        jobordereditor = new JobOrderEditor (database);
        jobordereditor.closed.connect (() => {
            /* FIXME: Lessen loading here */
            load_job_orders.begin ((obj, res) => {
                load_job_orders.end (res);
            });
        });
        jobordereditor.show ();
        stack.push (jobordereditor);
    }

    [CCode (instance_pos = -1)]
    public void on_button_print_clicked (Button button) {
        if (list == null)
            return;

        list.foreach ((model, path, iter) => {
            var id = 0;
            var ref_num = 0;
            bool selected;

            list.get (iter,
                      Database.JobOrdersListColumns.ID, out id,
                      Database.JobOrdersListColumns.REF_NUM, out ref_num,
                      View.ModelColumns.SELECTED, out selected);

            return false;
        });
    }

}
