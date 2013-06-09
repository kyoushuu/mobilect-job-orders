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

public class Mpcjo.JobOrderListView : Bin {

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
        }
    }

    private TreeView treeview;

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

            treeview = builder.get_object ("treeview") as TreeView;
            add (treeview);

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
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

}
