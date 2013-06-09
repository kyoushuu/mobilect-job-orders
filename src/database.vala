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

public class Database : Object {

    public enum JobOrdersListColumns {
        ID,
        REF_NUM,
        DESCRIPTION,
        CUSTOMER,
        ADDRESS,
        DATE_START,
        DATE_END,
        PURCHASE_ORDER_REF_NUM,
        PURCHASE_ORDER_DATE,
        VISIBLE,
        NUM
    }

    public enum CustomersListColumns {
        ID,
        NAME,
        ADDRESS,
        NUM
    }

    public Connection cnc;
    public DataHandler dh_string;

    public Database (string cnc_string) throws Error {
        /* Connect to database */
        cnc = Connection.open_from_string (null,
                                           cnc_string,
                                           null,
                                           ConnectionOptions.THREAD_SAFE);

        dh_string = cnc.get_provider ()
            .get_data_handler_g_type (cnc, typeof (string));
    }

    public async void initialize () throws Error {
        SourceFunc callback = initialize.callback;

        debug ("Initializing database");

        ThreadFunc<Error?> run = () => {
            cnc.lock ();

            try {
                /* Create employees table if doesn't exists */
                execute_sql ("CREATE TABLE IF NOT EXISTS job_orders (" +
                             "  id integer primary key autoincrement," +
                             "  ref_number integer not null," +
                             "  description string," +
                             "  customer integer not null," +
                             "  address string," +
                             "  date_start string," +
                             "  date_end string," +
                             "  purchase_order integer" +
                             ")");

                /* Create customers table if doesn't exists */
                execute_sql ("CREATE TABLE IF NOT EXISTS customers (" +
                             "  id integer primary key autoincrement," +
                             "  name string not null," +
                             "  address string" +
                             ")");

                /* Create purchase_orders table if doesn't exists */
                execute_sql ("CREATE TABLE IF NOT EXISTS purchase_orders (" +
                             "  id integer primary key autoincrement," +
                             "  ref_number integer not null," +
                             "  date string not null" +
                             ")");
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("initialize", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Initialized database");
    }

    private void execute_sql (string sql) throws Error {
        var stmt = cnc.parse_sql_string (sql, null);
        cnc.statement_execute_non_select (stmt, null, null);
    }

    public ListStore create_job_orders_list () {
        return new ListStore (JobOrdersListColumns.NUM,
                              typeof (int), typeof (int),        /* ID and Job order ref. num. */
                              typeof (string),                   /* Description */
                              typeof (string), typeof (string),  /* Customer and address */
                              typeof (string), typeof (string),  /* Start and end date */
                              typeof (int), typeof (string),     /* Purchase order */
                              typeof (bool));                    /* Visible */
    }

    public async bool load_job_orders_to_model (ListStore model) throws Error {
        SourceFunc callback = load_job_orders_to_model.callback;

        debug ("Queue loading of job orders");

        ThreadFunc<Error?> run = () => {
            DataModel dm = null;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("SELECT" +
                                                 " job_orders.id, job_orders.ref_number," +
                                                 " description," +
                                                 " customers.name, job_orders.address," +
                                                 " date_start, date_end," +
                                                 " purchase_orders.ref_number, purchase_orders.date " +
                                                 "FROM job_orders " +
                                                 "LEFT JOIN customers ON (job_orders.customer = customers.id) " +
                                                 "LEFT JOIN purchase_orders ON (job_orders.purchase_order = purchase_orders.id)",
                                                 null);
                dm = cnc.statement_execute_select (stmt, null);
            } catch (Error e) {
                warning ("Failed to get job orders: %s", e.message);

                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            if (dm == null) {
                /* FIXME: Should throw an error here */
                Idle.add((owned) callback);
                return null;
            }

            debug ("Got data model of job orders");

            var iter = dm.create_iter ();
            while (iter.move_next ()) {
                Value? column;
                int i = 0;

                var id = (int) iter.get_value_at (i++);
                var jo_number = (int) iter.get_value_at (i++);

                column = iter.get_value_at (i++);
                var description = dh_string.get_str_from_value (column);

                column = iter.get_value_at (i++);
                var customer = dh_string.get_str_from_value (column);

                column = iter.get_value_at (i++);
                var address = dh_string.get_str_from_value (column);

                column = iter.get_value_at (i++);
                var date_start = dh_string.get_str_from_value (column);

                column = iter.get_value_at (i++);
                var date_end = dh_string.get_str_from_value (column);

                column = iter.get_value_at (i++);
                var po_number = (!column.holds (typeof (Null))?
                                 (int) column : 0);

                column = iter.get_value_at (i++);
                var date_po = dh_string.get_str_from_value (column);

                debug ("Queued insertion of job order with id number %d to tree model", id);
                Idle.add (() => {
                    model.insert_with_values (null, -1,
                                              JobOrdersListColumns.ID, id,
                                              JobOrdersListColumns.REF_NUM, jo_number,
                                              JobOrdersListColumns.DESCRIPTION, description,
                                              JobOrdersListColumns.CUSTOMER, customer,
                                              JobOrdersListColumns.ADDRESS, address,
                                              JobOrdersListColumns.DATE_START, date_start,
                                              JobOrdersListColumns.DATE_END, date_end,
                                              JobOrdersListColumns.PURCHASE_ORDER_REF_NUM, po_number,
                                              JobOrdersListColumns.PURCHASE_ORDER_DATE, date_po,
                                              JobOrdersListColumns.VISIBLE, true);

                    debug ("Inserted job order with id number %d to tree model", id);

                    return false;
                });
            }

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("ljo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued loading of job orders");

        return true;
    }

    public ListStore create_customers_list () {
        return new ListStore (CustomersListColumns.NUM,
                              typeof (int),     /* ID */
                              typeof (string),  /* Name */
                              typeof (string)); /* Address */
    }

    public async bool load_customers_to_model (ListStore model) throws Error {
        SourceFunc callback = load_customers_to_model.callback;

        debug ("Queue loading of customers");

        ThreadFunc<Error?> run = () => {
            DataModel dm = null;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("SELECT" +
                                                 " id, name, address " +
                                                 "FROM customers",
                                                 null);
                dm = cnc.statement_execute_select (stmt, null);
            } catch (Error e) {
                warning ("Failed to get customers: %s", e.message);

                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            if (dm == null) {
                /* FIXME: Should throw an error here */
                Idle.add((owned) callback);
                return null;
            }

            debug ("Got data model of customers");

            var iter = dm.create_iter ();
            while (iter.move_next ()) {
                Value? column;
                int i = 0;

                var id = (int) iter.get_value_at (i++);

                column = iter.get_value_at (i++);
                var name = dh_string.get_str_from_value (column);

                column = iter.get_value_at (i++);
                var address = dh_string.get_str_from_value (column);

                debug ("Queued insertion of customer with id number %d to tree model", id);
                Idle.add (() => {
                    model.insert_with_values (null, -1,
                                              CustomersListColumns.ID, id,
                                              CustomersListColumns.NAME, name,
                                              CustomersListColumns.ADDRESS, address);

                    debug ("Inserted customer with id number %d to tree model", id);

                    return false;
                });
            }

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("lc", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued loading of customers");

        return true;
    }

}
