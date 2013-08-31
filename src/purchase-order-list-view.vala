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

public class Mpcjo.PurchaseOrderListView : View {

    public Database database { public get; private set; }

    public signal void purchase_order_selected (int id);

    private PurchaseOrderEditor purchaseordereditor;

    private TreeViewColumn treeviewcolumn_purchase_order;
    private CellRendererText cellrenderertext_purchase_order_number;
    private TreeViewColumn treeviewcolumn_date;
    private CellRendererText cellrenderertext_date;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/purchase-order-list-view.ui");
            builder.connect_signals (this);

            treeviewcolumn_purchase_order = builder.get_object ("treeviewcolumn_purchase_order") as TreeViewColumn;
            cellrenderertext_purchase_order_number = builder.get_object ("cellrenderertext_purchase_order_number") as CellRendererText;
            treeview.append_column (treeviewcolumn_purchase_order);

            treeviewcolumn_date = builder.get_object ("treeviewcolumn_date") as TreeViewColumn;
            cellrenderertext_date = builder.get_object ("cellrenderertext_date") as CellRendererText;
            treeview.append_column (treeviewcolumn_date);

            treeviewcolumn_purchase_order.set_cell_data_func (cellrenderertext_purchase_order_number, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                int refnum;

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.PurchaseOrdersListColumns.REF_NUM, out refnum);

                if (refnum > 0) {
                    cellrenderertext_purchase_order_number.markup = _("P.O. #%d").printf (refnum);
                } else {
                    cellrenderertext_purchase_order_number.markup = _("Unreleased");
                }
            });

            treeviewcolumn_date.set_cell_data_func (cellrenderertext_date, (column, cell, model, sort_iter) => {
                TreeIter filter_iter, iter;
                string date_string;
                var date = Date ();
                char s[64];

                sort.convert_iter_to_child_iter (out filter_iter, sort_iter);
                filter.convert_iter_to_child_iter (out iter, filter_iter);

                list.get (iter, Database.PurchaseOrdersListColumns.DATE, out date_string);

                if (date_string != null && date_string != "") {
                    date.set_parse (date_string);
                    date.strftime (s, "%a, %d %b, %Y");
                    cellrenderertext_date.markup = (string) s;
                } else {
                    cellrenderertext_date.markup = null;
                }
            });
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public PurchaseOrderListView (Database database) {
        this.database = database;
        /* Load purchase orders */
        load_purchase_orders.begin ((obj, res) => {
        });
    }

    public override void new_activated () {
        create_editor ();
        purchaseordereditor.create_new.begin ();
    }

    public override void item_activated (TreeIter iter) {
        int id;
        list.get (iter, Database.PurchaseOrdersListColumns.ID, out id);

        create_editor ();
        purchaseordereditor.edit.begin (id);
        purchase_order_selected (id);
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
                      Database.PurchaseOrdersListColumns.ID, out id,
                      View.ModelColumns.SELECTED, out selected);

            if (selected) {
                iter_selected = iter;
            }

            return selected;
        });

        if (iter_selected != null) {
            int id;

            list.get (iter_selected,
                      Database.PurchaseOrdersListColumns.ID, out id,
                      Database.PurchaseOrdersListColumns.REF_NUM, out ref_num);

            return id;
        } else {
            return 0;
        }
    }

    public async void load_purchase_orders () {
        debug ("Request loading of purchase orders");

        list = database.create_purchase_orders_list ();
        database.load_purchase_orders_to_model.begin (list);

        debug ("Request to load purchase orders succeeded");
    }

    private void create_editor () {
        purchaseordereditor = new PurchaseOrderEditor (database);
        purchaseordereditor.closed.connect (() => {
            /* FIXME: Lessen loading here */
            load_purchase_orders.begin ((obj, res) => {
                load_purchase_orders.end (res);
            });
        });
        purchaseordereditor.show ();
        stack.push (purchaseordereditor);
    }

}
