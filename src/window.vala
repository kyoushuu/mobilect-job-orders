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
using Mpcw;

[GtkTemplate (ui = "/com/mobilectpower/JobOrders/window.ui")]
public class Mpcjo.Window : Mpcw.Window {

    private StackSwitcher switcher;

    private Mpcw.Stack jo_stack;
    private StackPage jo_page;
    private JobOrderListView jo_view;
    private ulong jo_show_handler;

    private Mpcw.Stack po_stack;
    private StackPage po_page;
    private PurchaseOrderListView po_view;
    private ulong po_show_handler;

    private Mpcw.Stack in_stack;
    private StackPage in_page;
    private InvoiceListView in_view;
    private ulong in_show_handler;

    public Mpcjo.Application app {
        public get {
            return application as Mpcjo.Application;
        }
        public set {
            application = value;
        }
    }

    construct {
    }

    public Window (Application application) {
        this.app = application;
    }

    public void initialize () {
        stack.show_back_button = false;
        stack.transition_type = StackTransitionType.SLIDE_LEFT_RIGHT;

        switcher = new StackSwitcher ();
        switcher.stack = stack;
        switcher.show ();

        jo_page = new StackPage ();
        jo_page.show ();
        stack.push (jo_page, "jo_page", "Job Orders");

        jo_stack = new Mpcw.Stack (headerbar);
        jo_stack.transition_type = StackTransitionType.SLIDE_UP_DOWN;
        jo_stack.show ();
        jo_page.add (jo_stack);

        po_page = new StackPage ();
        po_page.show ();
        stack.push (po_page, "po_page", "Purchase Orders");

        po_stack = new Mpcw.Stack (headerbar);
        po_stack.transition_type = StackTransitionType.SLIDE_UP_DOWN;
        po_stack.show ();
        po_page.add (po_stack);

        in_page = new StackPage ();
        in_page.show ();
        stack.push (in_page, "in_page", "Invoices");

        in_stack = new Mpcw.Stack (headerbar);
        in_stack.transition_type = StackTransitionType.SLIDE_UP_DOWN;
        in_stack.show ();
        in_page.add (in_stack);

        jo_show_handler = jo_page.shown.connect (() => {
            jo_view = new JobOrderListView (app.database);
            jo_view.shown.connect (() => {
                headerbar.custom_title = switcher;
            });
            jo_view.hidden.connect (() => {
                headerbar.custom_title = null;
            });
            jo_view.notify["selection-mode-enabled"].connect (() => {
                if (!jo_view.selection_mode_enabled) {
                    headerbar.custom_title = switcher;
                }
            });
            jo_view.show ();
            jo_stack.push (jo_view);
        });
        jo_page.hidden.connect (() => {
            jo_stack.pop ();
        });

        po_show_handler = po_page.shown.connect (() => {
            po_view = new PurchaseOrderListView (app.database);
            po_view.shown.connect (() => {
                headerbar.custom_title = switcher;
            });
            po_view.hidden.connect (() => {
                headerbar.custom_title = null;
            });
            po_view.notify["selection-mode-enabled"].connect (() => {
                if (!po_view.selection_mode_enabled) {
                    headerbar.custom_title = switcher;
                }
            });
            po_view.show ();
            po_stack.push (po_view);
        });
        po_page.hidden.connect (() => {
            po_stack.pop ();
        });

        in_show_handler = in_page.shown.connect (() => {
            in_view = new InvoiceListView (app.database);
            in_view.shown.connect (() => {
                headerbar.custom_title = switcher;
            });
            in_view.hidden.connect (() => {
                headerbar.custom_title = null;
            });
            in_view.notify["selection-mode-enabled"].connect (() => {
                if (!in_view.selection_mode_enabled) {
                    headerbar.custom_title = switcher;
                }
            });
            in_view.show ();
            in_stack.push (in_view);
        });
        in_page.hidden.connect (() => {
            in_stack.pop ();
        });

        delete_event.connect (() => {
            jo_page.disconnect (jo_show_handler);
            po_page.disconnect (po_show_handler);
            in_page.disconnect (in_show_handler);

            return false;
        });

        stack.visible_child = jo_page;
    }

}
