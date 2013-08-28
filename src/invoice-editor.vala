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
using Mpcw;

public class Mpcjo.InvoiceEditor : StackPage {

    public bool editable { public get; private set; }
    public Database database { public get; private set; }

    private int in_id;

    private SpinButton spinbutton_in_refnum;
    private DateEntry entry_in_date;
    private DateEntry entry_in_payment_date;
    private Entry entry_in_remarks;

    construct {
        try {
            var builder = new Builder ();
            builder.add_from_resource ("/com/mobilectpower/JobOrders/invoice-editor.ui");
            builder.connect_signals (this);

            var grid = builder.get_object ("grid") as Grid;
            add (grid);

            can_focus = true;

            spinbutton_in_refnum = builder.get_object ("spinbutton_in_refnum") as SpinButton;
            entry_in_date = builder.get_object ("entry_in_date") as DateEntry;
            entry_in_payment_date = builder.get_object ("entry_in_payment_date") as DateEntry;
            entry_in_remarks = builder.get_object ("entry_in_remarks") as Entry;
        } catch (Error e) {
            error ("Failed to create widget: %s", e.message);
        }
    }

    public InvoiceEditor (Database database) {
        this.database = database;
    }

    public override void close () {
        save.begin ((obj, res) => {
            if (save.end (res)) {
                base.close ();
            }
        });
    }

    private bool check_fields () {
        if (database == null) {
            return false;
        }

        return true;
    }

    private async void initialize () throws Error {
        lock (in_id) {
            in_id = 0;
        }

        spinbutton_in_refnum.value = 0;
        entry_in_date.entry.text = "";
        entry_in_payment_date.entry.text = "";
        entry_in_remarks.text = "";
    }

    public async void create_new () throws Error {
        yield initialize ();
    }

    public async bool edit (int id) throws Error {
        SourceFunc callback = edit.callback;

        /* FIXME: Show loading indicator */
        yield initialize ();

        debug ("Loading invoice to edit");

        ThreadFunc<Error?> run = () => {
            DataModel dm = null;

            database.cnc.lock ();

            try {
                Gda.Set stmt_params;
                Value value_id = id;

                var stmt = database.cnc.
                    parse_sql_string ("SELECT" +
                                      " ref_number, date, " +
                                      " payment_date, remarks " +
                                      "FROM invoices " +
                                      "WHERE id=##id::int",
                                      out stmt_params);

                stmt_params.get_holder ("id").set_value (value_id);
                dm = database.cnc.statement_execute_select (stmt, stmt_params);
            } catch (Error e) {
                warning ("Failed to get invoices: %s", e.message);

                Idle.add((owned) callback);
                return e;
            } finally {
                database.cnc.unlock ();
            }

            if (dm == null || dm.get_n_rows () != 1) {
                /* FIXME: Throw an error here */
                Idle.add((owned) callback);
                return null;
            }

            var iter = dm.create_iter ();
            if (iter.move_next ()) {
                Value? column;
                Date date;
                char s[64];

                lock (in_id) {
                    in_id = id;
                }

                column = iter.get_value_at (0);
                var in_number = (!column.holds (typeof (Null))?
                                 (int) column : 0);

                column = iter.get_value_at (1);
                date = Date ();
                date.set_parse (database.dh_string.get_str_from_value (column));

                var date_in = "";
                if (date.valid ()) {
                    date.strftime (s, "%a, %d %b, %Y");
                    date_in = ((string) s).dup ();
                }

                column = iter.get_value_at (2);
                date = Date ();
                date.set_parse (database.dh_string.get_str_from_value (column));

                var payment_date_in = "";
                if (date.valid ()) {
                    date.strftime (s, "%a, %d %b, %Y");
                    payment_date_in = ((string) s).dup ();
                }

                column = iter.get_value_at (3);
                var remarks = database.dh_string.get_str_from_value (column);

                Idle.add (() => {
                    lock (in_id) {
                        entry_in_date.entry.sensitive = (in_id > 0);
                    }
                    spinbutton_in_refnum.value = in_number;
                    entry_in_date.entry.text = date_in;
                    entry_in_payment_date.entry.text = payment_date_in;
                    entry_in_remarks.text = remarks;

                    debug ("Finished loading of invoice data");

                    return false;
                });

                Idle.add((owned) callback);
                return null;
            } else {
                /* FIXME: Throw an error here */
                Idle.add((owned) callback);
                return null;
            }
        };
        var thread = new Thread<Error?> ("poe_e", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        return true;
    }

    public async bool save () {
        if (!check_fields ()) {
            return false;
        }

        try {
            database.cnc.lock ();
            database.cnc.begin_transaction (null, TransactionIsolation.REPEATABLE_READ);
            database.cnc.unlock ();

            try {
                /* FIXME: Check if reference number exists and id do not match (error for duplicates) */

                lock (in_id) {
                    if (in_id > 0) {
                        yield update_invoice ();
                    } else {
                        in_id = yield create_invoice ();
                    }
                }

                database.cnc.lock ();
                database.cnc.commit_transaction (null);
                database.cnc.unlock ();
            } catch (Error e) {
                database.cnc.lock ();
                database.cnc.rollback_transaction (null);
                database.cnc.unlock ();

                /* FIXME: Throw errors here */
                warning ("Failed to insert invoice: %s", e.message);

                return false;
            }
        } catch (Error e) {
            /* FIXME: Throw errors here */
            warning ("Failed to save invoice: %s", e.message);

            return false;
        }

        return true;
    }

    public async int create_invoice () throws Error {
        int ret = 0;

        ret = yield database.create_invoice ((int) spinbutton_in_refnum.value,
                                             entry_in_date.entry.text,
                                             entry_in_payment_date.entry.text,
                                             entry_in_remarks.text);

        return ret;
    }

    public async bool update_invoice () throws Error {
        bool ret = false;

        lock (in_id) {
            ret = yield database.update_invoice (in_id,
                                                 (int) spinbutton_in_refnum.value,
                                                 entry_in_date.entry.text,
                                                 entry_in_payment_date.entry.text,
                                                 entry_in_remarks.text);
        }

        return ret;
    }

    public async bool remove_invoice () throws Error {
        bool ret = false;

        lock (in_id) {
            ret = yield database.remove_invoice (in_id);
        }

        return ret;
    }

}
