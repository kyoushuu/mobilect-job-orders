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

public class Mpcjo.InvoiceListView : View {

    public Database database { public get; private set; }
    public int selected_items_num { public get; private set; }

    private ListStore? _list;
    public ListStore? list {
        get {
            return _list;
        }
        set {
            if (value != null) {
                _list = value;
                filter = new TreeModelFilter (value, null);

                sort = new TreeModelSort.with_model (filter);
                treeview.model = sort;
            } else {
                _list = null;
                filter = null;
                sort = null;
                treeview.model = null;
            }

            selected_items_num = 0;
        }
    }

    public signal void invoice_selected (int id);

    private InvoiceEditor invoiceeditor;
    private Overlay overlay;
    private TreeView treeview;

    private TreeViewColumn treeviewcolumn_selected;
    private TreeViewColumn treeviewcolumn_invoice;
    private CellRendererText cellrenderertext_invoice_number;
    private TreeViewColumn treeviewcolumn_date;
    private CellRendererText cellrenderertext_date;
    private TreeViewColumn treeviewcolumn_payment_date;
    private CellRendererText cellrenderertext_payment_date;
    private TreeViewColumn treeviewcolumn_remarks;
    private CellRendererText cellrenderertext_remarks;

    private TreeModelFilter filter;
    private TreeModelSort sort;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/invoice-list-view.ui");
            builder.connect_signals (this);

            overlay = builder.get_object ("overlay") as Overlay;
            add (overlay);

            treeview = builder.get_object ("treeview") as TreeView;

            treeviewcolumn_selected = builder.get_object ("treeviewcolumn_selected") as TreeViewColumn;
            treeviewcolumn_invoice = builder.get_object ("treeviewcolumn_invoice") as TreeViewColumn;
            cellrenderertext_invoice_number = builder.get_object ("cellrenderertext_invoice_number") as CellRendererText;
            treeviewcolumn_date = builder.get_object ("treeviewcolumn_date") as TreeViewColumn;
            cellrenderertext_date = builder.get_object ("cellrenderertext_date") as CellRendererText;
            treeviewcolumn_payment_date = builder.get_object ("treeviewcolumn_payment_date") as TreeViewColumn;
            cellrenderertext_payment_date = builder.get_object ("cellrenderertext_payment_date") as CellRendererText;
            treeviewcolumn_remarks = builder.get_object ("treeviewcolumn_remarks") as TreeViewColumn;
            cellrenderertext_remarks = builder.get_object ("cellrenderertext_remarks") as CellRendererText;

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

            /* Clear selection when selection mode is disabled */
            notify["selection-mode-enabled"].connect (() => {
                if (selection_mode_enabled == false) {
                    select_none ();
                }
            });

            /* Show select column if select is active */
            bind_property ("selection-mode-enabled", treeviewcolumn_selected, "visible",
                           BindingFlags.SYNC_CREATE);
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
        invoiceeditor.create_new.begin ();
    }

    public override void close () {
        if (selection_mode_enabled && selected_items_num == 1) {
            base.close ();
        }
    }

    public int get_selected_item (out int ref_num) {
        TreeIter? iter_selected = null;

        ref_num = 0;
        if (list == null)
            return 0;

        list.foreach ((model, path, iter) => {
            int id;
            bool selected;

            list.get (iter,
                      Database.InvoicesListColumns.ID, out id,
                      Database.InvoicesListColumns.SELECTED, out selected);

            if (selected) {
                iter_selected = iter;
            }

            return selected;
        });

        if (iter_selected != null) {
            int id;

            list.get (iter_selected,
                      Database.InvoicesListColumns.ID, out id,
                      Database.InvoicesListColumns.REF_NUM, out ref_num);

            return id;
        } else {
            return 0;
        }
    }

    public void select_all () {
        if (list == null)
            return;

        selected_items_num = 0;
        list.foreach ((model, path, iter) => {
            list.set (iter, Database.InvoicesListColumns.SELECTED, true);
                selected_items_num++;

                return false;
        });
    }

    public void select_none () {
        if (list == null)
            return;

        list.foreach ((model, path, iter) => {
            list.set (iter, Database.InvoicesListColumns.SELECTED, false);

            return false;
        });
        selected_items_num = 0;
    }

    public async void load_invoices () {
        debug ("Request loading of invoices");

        list = database.create_invoices_list ();
        database.load_invoices_to_model.begin (list);

        debug ("Request to load invoices succeeded");
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
    public void on_treeview_row_activated (TreeView tree_view,
                                           TreePath path,
                                           TreeViewColumn column) {
        TreeIter sort_iter, filter_iter, iter;

        if (sort.get_iter (out sort_iter, path)) {
            sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
            filter.convert_iter_to_child_iter (out iter, filter_iter);

            if (selection_mode_enabled) {
                bool selected;
                list.get (iter, Database.InvoicesListColumns.SELECTED, out selected);

                if (selected) {
                    selected_items_num--;
                } else {
                    selected_items_num++;
                }

                selected = !selected;
                list.set (iter, Database.InvoicesListColumns.SELECTED, selected);
            } else {
                int id;
                list.get (iter, Database.InvoicesListColumns.ID, out id);

                create_editor ();
                invoiceeditor.edit.begin (id);
                invoice_selected (id);
            }
        }
    }

}
