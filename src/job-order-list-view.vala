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

    public signal void job_order_selected (int id);

    private JobOrderEditor jobordereditor;
    private Overlay overlay;
    private TreeView treeview;

    private TreeViewColumn treeviewcolumn_selected;
    private TreeViewColumn treeviewcolumn_job_order;
    private CellRendererText cellrenderertext_job_order_number;
    private TreeViewColumn treeviewcolumn_customer;
    private CellRendererText cellrenderertext_customer;
    private TreeViewColumn treeviewcolumn_date;
    private CellRendererText cellrenderertext_date;
    private TreeViewColumn treeviewcolumn_purchase_order;
    private CellRendererText cellrenderertext_purchase_order_number;

    private TreeModelFilter filter;
    private TreeModelSort sort;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/job-order-list-view.ui");
            builder.connect_signals (this);

            overlay = builder.get_object ("overlay") as Overlay;
            add (overlay);

            treeview = builder.get_object ("treeview") as TreeView;

            treeviewcolumn_selected = builder.get_object ("treeviewcolumn_selected") as TreeViewColumn;
            treeviewcolumn_job_order = builder.get_object ("treeviewcolumn_job_order") as TreeViewColumn;
            cellrenderertext_job_order_number = builder.get_object ("cellrenderertext_job_order_number") as CellRendererText;
            treeviewcolumn_customer = builder.get_object ("treeviewcolumn_customer") as TreeViewColumn;
            cellrenderertext_customer = builder.get_object ("cellrenderertext_customer") as CellRendererText;
            treeviewcolumn_date = builder.get_object ("treeviewcolumn_date") as TreeViewColumn;
            cellrenderertext_date = builder.get_object ("cellrenderertext_date") as CellRendererText;
            treeviewcolumn_purchase_order = builder.get_object ("treeviewcolumn_purchase_order") as TreeViewColumn;
            cellrenderertext_purchase_order_number = builder.get_object ("cellrenderertext_purchase_order_number") as CellRendererText;

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
                int refnum;
                string date_string;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

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
                } else {
                    cellrenderertext_purchase_order_number.markup = null;
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

    public JobOrderListView (Database database) {
        this.database = database;
        /* Load job orders */
        load_job_orders.begin ((obj, res) => {
        });
    }

    public override void new_activated () {
        create_editor ();
        jobordereditor.create_new.begin ();
    }

    public void select_all () {
        if (list == null)
            return;

        selected_items_num = 0;
        list.foreach ((model, path, iter) => {
            list.set (iter, Database.JobOrdersListColumns.SELECTED, true);
                selected_items_num++;

                return false;
        });
    }

    public void select_none () {
        if (list == null)
            return;

        list.foreach ((model, path, iter) => {
            list.set (iter, Database.JobOrdersListColumns.SELECTED, false);

            return false;
        });
        selected_items_num = 0;
    }

    public async void load_job_orders () {
        debug ("Request loading of job orders");

        list = database.create_job_orders_list ();
        database.load_job_orders_to_model.begin (list);

        debug ("Request to load job orders succeeded");
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
    public void on_treeview_row_activated (TreeView tree_view,
                                           TreePath path,
                                           TreeViewColumn column) {
        TreeIter sort_iter, filter_iter, iter;

        if (sort.get_iter (out sort_iter, path)) {
            sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
            filter.convert_iter_to_child_iter (out iter, filter_iter);

            if (selection_mode_enabled) {
                bool selected;
                list.get (iter, Database.JobOrdersListColumns.SELECTED, out selected);

                if (selected) {
                    selected_items_num--;
                } else {
                    selected_items_num++;
                }

                selected = !selected;
                list.set (iter, Database.JobOrdersListColumns.SELECTED, selected);
            } else {
                int id;
                list.get (iter, Database.JobOrdersListColumns.ID, out id);

                create_editor ();
                jobordereditor.edit.begin (id);
                job_order_selected (id);
            }
        }
    }

}
