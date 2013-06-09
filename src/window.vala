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
using Gd;

public class Mpcjo.Window : ApplicationWindow {

    public Stack stack_view;
    public JobOrderListView joborderlistview;

    public Mpcjo.Application app {
        public get {
            return application as Mpcjo.Application;
        }
        public set {
            application = value;
        }
    }

    construct {
        try {
            Gd.ensure_types ();

            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/window.ui");
            builder.connect_signals (this);

            var box = builder.get_object ("box") as Box;
            add (box);

            stack_view = builder.get_object ("stack_view") as Stack;
            joborderlistview = builder.get_object ("joborderlistview") as JobOrderListView;
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public Window (Application application) {
        this.app = application;
    }

}
