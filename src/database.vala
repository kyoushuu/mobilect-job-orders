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
        SELECTED,
        NUM
    }

    public enum CustomersListColumns {
        ID,
        NAME,
        ADDRESS,
        NUM
    }

    public enum PurchaseOrdersListColumns {
        ID,
        REF_NUM,
        DATE,
        VISIBLE,
        SELECTED,
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
                              typeof (bool), typeof (bool));     /* Visible and selected */
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
                                              JobOrdersListColumns.VISIBLE, true,
                                              JobOrdersListColumns.SELECTED, false);

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

    public ListStore create_purchase_orders_list () {
        return new ListStore (PurchaseOrdersListColumns.NUM,
                              typeof (int), typeof (int),        /* ID and Purchase order ref. num. */
                              typeof (string),                   /* Date */
                              typeof (bool), typeof (bool));     /* Visible and selected */
    }

    public async bool load_purchase_orders_to_model (ListStore model) throws Error {
        SourceFunc callback = load_purchase_orders_to_model.callback;

        debug ("Queue loading of purchase orders");

        ThreadFunc<Error?> run = () => {
            DataModel dm = null;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("SELECT" +
                                                 " id, ref_number," +
                                                 " date " +
                                                 "FROM purchase_orders",
                                                 null);
                dm = cnc.statement_execute_select (stmt, null);
            } catch (Error e) {
                warning ("Failed to get purchase orders: %s", e.message);

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

            debug ("Got data model of purchase orders");

            var iter = dm.create_iter ();
            while (iter.move_next ()) {
                Value? column;
                int i = 0;

                var id = (int) iter.get_value_at (i++);
                var po_number = (int) iter.get_value_at (i++);

                column = iter.get_value_at (i++);
                var date_po = dh_string.get_str_from_value (column);

                debug ("Queued insertion of purchase order with id number %d to tree model", id);
                Idle.add (() => {
                    model.insert_with_values (null, -1,
                                              PurchaseOrdersListColumns.ID, id,
                                              PurchaseOrdersListColumns.REF_NUM, po_number,
                                              PurchaseOrdersListColumns.DATE, date_po,
                                              PurchaseOrdersListColumns.VISIBLE, true,
                                              PurchaseOrdersListColumns.SELECTED, false);

                    debug ("Inserted purchase order with id number %d to tree model", id);

                    return false;
                });
            }

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("lpo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued loading of purchase orders");

        return true;
    }

    public async int create_job_order (int refnum, int customer_id, string desc, string address, string date_start, string date_end, int po_id) throws Error {
        SourceFunc callback = create_job_order.callback;
        int jo_id = 0;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params, last_insert_row;
            Value? value_jo_ref_number = null, value_jo_customer = null, value_po_id = null;

            debug ("Queue creation of job order with reference number %d", refnum);

            value_jo_ref_number = refnum;
            value_jo_customer = customer_id;

            if (po_id > 0) {
                value_po_id = po_id;
            } else {
                value_po_id = null;
            }

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("INSERT INTO job_orders (" +
                                                 " ref_number," +
                                                 " description," +
                                                 " customer, address," +
                                                 " date_start, date_end," +
                                                 " purchase_order" +
                                                 ") VALUES (" +
                                                 " ##ref_number::int," +
                                                 " ##description::string," +
                                                 " ##customer::int," +
                                                 " ##address::string," +
                                                 " ##date_start::string," +
                                                 " ##date_end::string," +
                                                 " ##purchase_order::int::null" +
                                                 ")",
                                                 out stmt_params);

                stmt_params.get_holder ("ref_number").set_value (value_jo_ref_number);
                stmt_params.get_holder ("description").set_value_str (null, desc);
                stmt_params.get_holder ("customer").set_value (value_jo_customer);
                stmt_params.get_holder ("address").set_value_str (null, address);
                stmt_params.get_holder ("date_start").set_value_str (null, date_start);
                stmt_params.get_holder ("date_end").set_value_str (null, date_end);
                stmt_params.get_holder ("purchase_order").set_value (value_po_id);
                cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);

                if (last_insert_row != null) {
                    jo_id = last_insert_row.get_holder_value ("+0").get_int ();
                } else {
                    /* FIXME: Get row here */
                }
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Job order with reference number %d successfully created", refnum);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("cjo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued creation of job order with reference number %d", refnum);

        return jo_id;
    }

    public async bool update_job_order (int jo_id, int refnum, int customer_id, string desc, string address, string date_start, string date_end, int po_id) throws Error {
        SourceFunc callback = update_job_order.callback;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params;
            Value? value_jo_id, value_jo_ref_number = null, value_jo_customer = null, value_po_id = null;

            debug ("Queue update of job order with reference number %d", refnum);

            value_jo_id = jo_id;
            value_jo_ref_number = refnum;
            value_jo_customer = customer_id;

            if (po_id > 0) {
                value_po_id = po_id;
            } else {
                value_po_id = null;
            }

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("UPDATE job_orders " +
                                                 "SET " +
                                                 " ref_number=##ref_number::int," +
                                                 " description=##description::string," +
                                                 " customer=##customer::int," +
                                                 " address=##address::string," +
                                                 " date_start=##date_start::string," +
                                                 " date_end=##date_end::string," +
                                                 " purchase_order=##purchase_order::int::null " +
                                                 "WHERE id=##id::int",
                                                 out stmt_params);
                stmt_params.get_holder ("id").set_value (value_jo_id);
                stmt_params.get_holder ("ref_number").set_value (value_jo_ref_number);
                stmt_params.get_holder ("description").set_value_str (null, desc);
                stmt_params.get_holder ("customer").set_value (value_jo_customer);
                stmt_params.get_holder ("address").set_value_str (null, address);
                stmt_params.get_holder ("date_start").set_value_str (null, date_start);
                stmt_params.get_holder ("date_end").set_value_str (null, date_end);
                stmt_params.get_holder ("purchase_order").set_value (value_po_id);
                cnc.statement_execute_non_select (stmt, stmt_params, null);
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Job order with reference number %d successfully updated", refnum);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("ujo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued update of job order with reference number %d", refnum);

        return true;
    }

    /* FIXME: Remove also the purchase order here */
    public async bool remove_job_order (int jo_id) throws Error {
        SourceFunc callback = remove_job_order.callback;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params;
            Value? value_jo_id;

            debug ("Queue removal of job order with id number %d", jo_id);

            value_jo_id = jo_id;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("DELETE FROM job_orders WHERE id=##id::int",
                                                 out stmt_params);
                stmt_params.get_holder ("id").set_value (value_jo_id);
                cnc.statement_execute_non_select (stmt, stmt_params, null);
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Job order with id number %d successfully removed", jo_id);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("rjo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued removal of job order with id number %d", jo_id);

        return true;
    }

    public async int get_customer_id (string name) throws Error {
        SourceFunc callback = get_customer_id.callback;
        int customer_id = 0;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params;

            debug ("Looking for ID of customer with name \"%s\"", name);

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("SELECT id FROM customers WHERE name=##name::string",
                                                 out stmt_params);
                stmt_params.get_holder ("name").set_value_str (null, name);

                var dm = cnc.statement_execute_select (stmt, stmt_params);
                var iter = dm.create_iter ();
                if (iter.move_next ()) {
                    customer_id = (int) iter.get_value_at (0);
                }
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("ID of customer with name \"%s\" found", name);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("rc", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Finished search for ID of customer with name \"%s\"", name);

        return customer_id;
    }

    public async int create_customer (string name, string address) throws Error {
        SourceFunc callback = create_customer.callback;
        int customer_id = 0;

        debug ("Queue creation of customer with name \"%s\"", name);

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params, last_insert_row;

            debug ("Queue creation of customer with name \"%s\"", name);

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("INSERT INTO customers (" +
                                                 " name, address" +
                                                 ") VALUES (" +
                                                 " ##name::string," +
                                                 " ##address::string::null" +
                                                 ")",
                                                 out stmt_params);

                stmt_params.get_holder ("name").set_value_str (null, name);
                stmt_params.get_holder ("address").set_value_str (null, address);
                cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);

                if (last_insert_row != null) {
                    customer_id = last_insert_row.get_holder_value ("+0").get_int ();
                } else {
                    /* FIXME: Get row here */
                }
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Customer with name \"%s\" successfully created", name);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("cc", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued creation of customer with name \"%s\"", name);

        return customer_id;
    }

    public async bool remove_customer (int customer_id) throws Error {
        SourceFunc callback = remove_customer.callback;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params;
            Value? value_customer_id;

            debug ("Queue removal of customer with id number %d", customer_id);

            value_customer_id = customer_id;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("DELETE FROM customers WHERE id=##id::int",
                                                 out stmt_params);
                stmt_params.get_holder ("id").set_value (value_customer_id);
                cnc.statement_execute_non_select (stmt, stmt_params, null);
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Customer with id number %d successfully removed", customer_id);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("rc", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued removal of customer with id number %d", customer_id);

        return true;
    }

    public async int create_purchase_order (int refnum, string date) throws Error {
        SourceFunc callback = create_purchase_order.callback;
        int po_id = 0;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params, last_insert_row;
            Value? value_po_ref_number;

            debug ("Queue creation of purchase order with reference number %d", refnum);

            value_po_ref_number = refnum;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("INSERT INTO purchase_orders (" +
                                                 " ref_number," +
                                                 " date" +
                                                 ") VALUES (" +
                                                 " ##ref_number::int," +
                                                 " ##date::string::null" +
                                                 ")",
                                                 out stmt_params);

                stmt_params.get_holder ("ref_number").set_value (value_po_ref_number);
                stmt_params.get_holder ("date").set_value_str (null, date);
                cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);

                if (last_insert_row != null) {
                    po_id = last_insert_row.get_holder_value ("+0").get_int ();
                } else {
                    /* FIXME: Get row here */
                }
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Purchase order with reference number %d successfully created", refnum);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("cpo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued creation of purchase order with reference number %d", refnum);

        return po_id;
    }

    public async bool update_purchase_order (int po_id, int refnum, string date) throws Error {
        SourceFunc callback = update_purchase_order.callback;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params;
            Value? value_po_id, value_po_ref_number;

            debug ("Queue update of purchase order with reference number %d", refnum);

            value_po_id = po_id;
            value_po_ref_number = refnum;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("UPDATE purchase_orders " +
                                                 "SET " +
                                                 " ref_number=##ref_number::int," +
                                                 " date=##date::string " +
                                                 "WHERE id=##id::int",
                                                 out stmt_params);
                stmt_params.get_holder ("id").set_value (value_po_id);
                stmt_params.get_holder ("ref_number").set_value (value_po_ref_number);
                stmt_params.get_holder ("date").set_value_str (null, date);
                cnc.statement_execute_non_select (stmt, stmt_params, null);
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Purchase order with reference number %d successfully updated", refnum);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("upo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued update of purchase order with reference number %d", refnum);

        return true;
    }

    public async bool remove_purchase_order (int po_id) throws Error {
        SourceFunc callback = remove_purchase_order.callback;

        ThreadFunc<Error?> run = () => {
            Gda.Set stmt_params;
            Value? value_po_id;

            debug ("Queue removal of purchase order with id number %d", po_id);

            value_po_id = po_id;

            cnc.lock ();

            try {
                var stmt = cnc.parse_sql_string ("DELETE FROM purchase_orders WHERE id=##id::int",
                                                 out stmt_params);
                stmt_params.get_holder ("id").set_value (value_po_id);
                cnc.statement_execute_non_select (stmt, stmt_params, null);
            } catch (Error e) {
                Idle.add((owned) callback);
                return e;
            } finally {
                cnc.unlock ();
            }

            debug ("Purchase order with id number %d successfully removed", po_id);

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("rpo", run);

        yield;

        var e = thread.join ();
        if (e != null) {
            throw e;
        }

        debug ("Queued removal of purchase order with id number %d", po_id);

        return true;
    }

}
