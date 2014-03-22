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

public class Mpcjo.Application : Gtk.Application {

    public Database database;

    public Application () {
        Object (application_id: "com.mobilectpower.JobOrders");
    }

    public override void startup () {
        base.startup ();

        try {
            /* Create config directory with permission 0754 */
            var db_dir = Path.build_filename (Environment.get_user_config_dir (), Config.PACKAGE);
            DirUtils.create_with_parents (db_dir, 0754);

            database = new Database ("SQLite://DB_DIR=%s;DB_NAME=%s".printf (db_dir, Config.PACKAGE));
            database.initialize.begin ();
        } catch (Error e) {
            var e_dialog = new MessageDialog (null, DialogFlags.MODAL,
                                              MessageType.ERROR, ButtonsType.OK,
                                              "Failed to load database.");
            e_dialog.secondary_text = e.message;
            e_dialog.run ();
            e_dialog.destroy ();
        }
    }

    public override void activate () {
        if (database == null) {
            return;
        }

        var window = new Window (this);
        window.initialize ();
        window.present ();
    }

}
