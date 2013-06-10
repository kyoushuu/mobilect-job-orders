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

    public HeaderBar headerbar;
    public HeaderSimpleButton button_new;
    public HeaderSimpleButton button_back;
    public Stack stack_view;

    public JobOrderListView joborderlistview;
    public JobOrderEditor jobordereditor;

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

            headerbar = builder.get_object ("headerbar") as HeaderBar;
            button_new = builder.get_object ("button_new") as HeaderSimpleButton;
            button_back = builder.get_object ("button_back") as HeaderSimpleButton;
            stack_view = builder.get_object ("stack_view") as Stack;
            joborderlistview = builder.get_object ("joborderlistview") as JobOrderListView;

            /* Hide/Show main view buttons when back buttons is shown/hidden */
            button_back.bind_property ("visible", button_new, "visible",
                                       BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public Window (Application application) {
        this.app = application;
    }

    public void initialize () {
        /* Load job orders */
        load_job_orders.begin ((obj, res) => {
        });
    }

    public async void load_job_orders () {
        debug ("Request loading of job orders");

        var list = app.database.create_job_orders_list ();
        joborderlistview.list = list;

        app.database.load_job_orders_to_model.begin (list);

        debug ("Request to load job orders succeeded");
    }

    [CCode (instance_pos = -1)]
    public void on_stack_add_remove (Container container,
                                     Widget widget) {
        var children = stack_view.get_children();
        button_back.visible = children.length () > 1;
    }

    [CCode (instance_pos = -1)]
    public void on_button_new_clicked (Button button) {
        jobordereditor = new JobOrderEditor (app.database);
        jobordereditor.show ();
        stack_view.add (jobordereditor);
        stack_view.set_visible_child (jobordereditor);
        jobordereditor.create_new.begin ();
    }

    [CCode (instance_pos = -1)]
    public void on_button_back_clicked (Button button) {
        if (jobordereditor != null) {
            jobordereditor.save.begin ((obj, res) => {
                if (jobordereditor.save.end (res)) {
                    debug ("Save finished");

                    jobordereditor.destroy ();
                    jobordereditor = null;

                    /* FIXME: Lessen loading here */
                    load_job_orders.begin ((obj, res) => {
                        load_job_orders.end (res);
                    });
                }
            });
        }
    }

    [CCode (instance_pos = -1)]
    public void on_joborderlistview_job_order_selected (JobOrderListView view,
                                                        int id) {
        jobordereditor = new JobOrderEditor (app.database);
        jobordereditor.show ();
        stack_view.add (jobordereditor);
        stack_view.set_visible_child (jobordereditor);
        jobordereditor.edit.begin (id);
    }

}
