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
using Pango;
using Mpcw;

public class Mpcjo.JobOrderListView : View {

    public Database database { public get; private set; }

    public signal void job_order_selected (int id);

    private JobOrderEditor jobordereditor;
    private Button button_print;

    private TreeViewColumn treeviewcolumn_job_order;
    private CellRendererText cellrenderertext_job_order_number;
    private TreeViewColumn treeviewcolumn_purchase_order;
    private CellRendererText cellrenderertext_purchase_order_number;
    private TreeViewColumn treeviewcolumn_invoice;
    private CellRendererText cellrenderertext_invoice_number;
    private TreeViewColumn treeviewcolumn_payment;
    private CellRendererText cellrenderertext_payment;

    private PrintSettings print_settings;

    private Cancellable cancel_load;

    public const string PAPER_NAME_FANFOLD_GERMAN_LEGAL = "na_foolscap";

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/job-order-list-view.ui");
            builder.connect_signals (this);

            button_print = builder.get_object ("button_print") as Button;
            toolbar_selection.pack_end (button_print);

            treeviewcolumn_job_order = builder.get_object ("treeviewcolumn_job_order") as TreeViewColumn;
            cellrenderertext_job_order_number = builder.get_object ("cellrenderertext_job_order_number") as CellRendererText;
            treeview.append_column (treeviewcolumn_job_order);

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
                        .printf (_("Not Yet Released"));
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

    public override void shown () {
        stack.headerbar.title = "Job Orders";
        base.shown ();
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

    public override void search_changed (string text) {
        var start = Date ();
        var end = Date ();
        Database.GeneralFilter filter = null;

        if (DateUtil.span_for_text (text, ref start, ref end)) {
            if (start.valid () && end.valid ()) {
                if (start.compare (end) != 0) {
                    filter = (row) => {
                        var jo_date_start = Date ();
                        jo_date_start.set_parse (row.jo_date_start);

                        return start.compare (jo_date_start) <= 0 &&
                            end.compare (jo_date_start) >= 0;
                    };
                } else {
                    filter = (row) => {
                        var jo_date_start = Date ();
                        jo_date_start.set_parse (row.jo_date_start);

                        return start.compare (jo_date_start) == 0;
                    };
                }
            } else if (start.valid ()) {
                filter = (row) => {
                    var jo_date_start = Date ();
                    jo_date_start.set_parse (row.jo_date_start);

                    return start.compare (jo_date_start) < 0;
                };
            } else if (end.valid ()) {
                filter = (row) => {
                    var jo_date_start = Date ();
                    jo_date_start.set_parse (row.jo_date_start);

                    return end.compare (jo_date_start) > 0;
                };
            }
        }

        if (this.cancel_load != null) {
            this.cancel_load.cancel ();
        }

        var cancel_load = new Cancellable ();
        this.cancel_load = cancel_load;
        list = database.create_job_orders_list ();

        if (filter != null) {
            database.load_job_orders_to_model.begin (list, filter, cancel_load, () => {
                if (this.cancel_load == cancel_load) {
                    this.cancel_load = null;
                }
            });
        }
    }

    public async void load_job_orders () {
        debug ("Request loading of job orders");

        if (this.cancel_load != null) {
            this.cancel_load.cancel ();
        }

        var cancel_load = new Cancellable ();
        this.cancel_load = cancel_load;

        list = database.create_job_orders_list ();
        database.load_job_orders_to_model.begin (list, null, cancel_load, () => {
            if (this.cancel_load == cancel_load) {
                this.cancel_load = null;
            }
        });

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
            if (!search_mode_enabled) {
                /* FIXME: Lessen loading here */
                load_job_orders.begin ((obj, res) => {
                    load_job_orders.end (res);
                });
            }
        });
        jobordereditor.show ();
        stack.push (jobordereditor);
    }

    [CCode (instance_pos = -1)]
    public void on_button_print_clicked (Button button) {
        var items = new TreeRowReference[0];

        if (list == null)
            return;

        list.foreach ((model, path, iter) => {
            bool selected;

            list.get (iter,
                      View.ModelColumns.SELECTED, out selected);

            if (selected) {
                items += new TreeRowReference (model, path);
            }

            return false;
        });

        var print = new PrintOperation ();
        print.embed_page_setup = true;

        var normal_font = FontDescription.from_string ("sans 12");
        var normal_font_height = 0.0;
        var pages = 0;
        var items_per_page = 0;

        print.begin_print.connect ((context) => {
            FontMetrics font_metrics;
            var pcontext = context.create_pango_context ();

            font_metrics = pcontext.load_font (normal_font).get_metrics (pcontext.get_language ());
            normal_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

            items_per_page = (int) Math.floor (context.get_height () / (normal_font_height * 2));
            pages = (int) Math.ceil ((double) items.length / items_per_page);

            print.set_n_pages (pages);
        });

        print.draw_page.connect ((context, page_nr) => {
            var cr = context.get_cairo_context ();

            var first_item = page_nr * items_per_page;
            var items_current_page = items_per_page;
            if (page_nr == pages - 1) {
                items_current_page = items.length % items_per_page;
            }

            cr.rectangle (0, 0, context.get_width (), items_current_page * normal_font_height * 2);
            cr.set_line_width (1.0);
            cr.stroke ();

            cr.set_line_width (0.5);

            for (var i = 1; i < items_current_page; i++) {
                cr.move_to (0, normal_font_height * 2 * i);
                cr.rel_line_to (context.get_width (), 0);
                cr.stroke ();
            }

            var layout = context.create_pango_layout ();
            layout.set_font_description (normal_font);
            layout.set_width (units_from_double (context.get_width ()));

            var padding = 2.0;
            var column_width = context.get_width () / 4;

            for (var i = 0; i < items_current_page; i++) {
                var ref_num = 0;
                string customer, project_name;
                string date_start, date_end;
                int po_id, po_refnum;
                string po_date;
                int in_refnum;
                string in_date, payment_date;
                TreeIter iter;

                var date = Date ();
                char s[64];

                list.get_iter (out iter, items[first_item + i].get_path ());
                list.get (iter,
                          Database.JobOrdersListColumns.REF_NUM, out ref_num,
                          Database.JobOrdersListColumns.CUSTOMER, out customer,
                          Database.JobOrdersListColumns.PROJECT_NAME, out project_name,
                          Database.JobOrdersListColumns.DATE_START, out date_start,
                          Database.JobOrdersListColumns.DATE_END, out date_end,
                          Database.JobOrdersListColumns.PURCHASE_ORDER_ID, out po_id,
                          Database.JobOrdersListColumns.PURCHASE_ORDER_REF_NUM, out po_refnum,
                          Database.JobOrdersListColumns.PURCHASE_ORDER_DATE, out po_date,
                          Database.JobOrdersListColumns.INVOICE_REF_NUM, out in_refnum,
                          Database.JobOrdersListColumns.INVOICE_DATE, out in_date,
                          Database.JobOrdersListColumns.PAYMENT_DATE, out payment_date);

                date.set_parse (date_start);
                date.strftime (s, "%a, %d %b, %Y");
                date_start = (string) s;

                date.set_parse (date_end);
                date.strftime (s, "%a, %d %b, %Y");
                date_end = (string) s;

                cr.move_to (padding, normal_font_height * 2 * i);

                layout.set_font_description (normal_font);
                layout.set_alignment (Pango.Alignment.LEFT);
                layout.set_height (units_from_double (normal_font_height));
                layout.set_width (units_from_double (column_width - padding * 2));
                layout.set_markup (_("J.O. #%d").printf (ref_num), -1);
                cairo_show_layout (cr, layout);

                cr.rel_move_to (column_width, 0);

                layout.set_font_description (normal_font);
                layout.set_alignment (Pango.Alignment.LEFT);
                layout.set_height (units_from_double (normal_font_height * 2));
                layout.set_width (units_from_double (column_width - padding * 2));
                if (po_refnum > 0) {
                    date.set_parse (po_date);
                    date.strftime (s, "%a, %d %b, %Y");

                    layout.set_markup (("<span color=\"#000000000000\">P.O. #%d</span>\n" +
                                        "<span color=\"#88888a8a8585\">%s</span>")
                                       .printf (po_refnum, (string) s), -1);
                } else if (po_id > 0) {
                    layout.set_markup (("<span color=\"#000000000000\">%s</span>\n")
                                       .printf (_("Not Yet Released")), -1);
                } else {
                    layout.set_markup ("", -1);
                }
                cairo_show_layout (cr, layout);

                cr.rel_move_to (column_width, 0);

                layout.set_font_description (normal_font);
                layout.set_alignment (Pango.Alignment.LEFT);
                layout.set_height (units_from_double (normal_font_height * 2));
                layout.set_width (units_from_double (column_width - padding * 2));
                if (in_refnum > 0) {
                    date.set_parse (in_date);
                    date.strftime (s, "%a, %d %b, %Y");

                    layout.set_markup (("<span color=\"#000000000000\">Invoice #%d</span>\n" +
                                        "<span color=\"#88888a8a8585\">%s</span>")
                                       .printf (in_refnum, (string) s), -1);
                } else {
                    layout.set_markup ("", -1);
                }
                cairo_show_layout (cr, layout);

                cr.rel_move_to (column_width, 0);

                if (payment_date != null && payment_date != "") {
                    date.set_parse (payment_date);
                    date.strftime (s, "%a, %d %b, %Y");

                    layout.set_markup (("<span color=\"#000000000000\">Paid</span>\n" +
                                        "<span color=\"#88888a8a8585\">%s</span>")
                                       .printf ((string) s), -1);
                } else {
                    layout.set_markup ("", -1);
                }
                cairo_show_layout (cr, layout);
            }
        });

        var page_setup = new PageSetup ();
        page_setup.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
        print.set_default_page_setup (page_setup);

        if (print_settings == null) {
            print_settings = new PrintSettings ();
            print_settings.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
        }
        print.set_print_settings (print_settings);

        try {
            var result = print.run (PrintOperationAction.PRINT_DIALOG, get_toplevel () as Window);
            if (result == PrintOperationResult.APPLY)
                print_settings = print.get_print_settings ();
        } catch (Error e) {
            var e_dialog = new MessageDialog (get_toplevel () as Window, DialogFlags.MODAL,
                                              MessageType.ERROR, ButtonsType.OK,
                                              "Failed to print job orders.");
            e_dialog.secondary_text = e.message;
            e_dialog.run ();
            e_dialog.destroy ();
        }
    }

}
