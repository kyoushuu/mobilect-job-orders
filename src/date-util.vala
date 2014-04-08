/*
 * Copyright (c) 2014 Mobilect Power Corp.
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

public struct Mpcjo.DateUtil {

    public DateDay day;
    public DateMonth month;
    public DateYear year;

    public DateUtil () {
        clear ();
    }

    public DateUtil.from_text (string text) {
        Regex mdy_regex, dmy_regex, ymd_regex;
        MatchInfo match_info;

        var str = text.strip ();

        try {
            var year_regex = "(?P<year>\\d{4})";
            var month_regex = "((?P<month>[a-zA-Z]{3,})\\.?)";
            var day_regex = "(?P<day>[1-3]?[0-9])";

            mdy_regex = new Regex ("^%s?((?(month)\\s+)?%s,?)?((?(month)\\s+|(?(day)\\s+|\\s*))%s)?$"
                .printf (month_regex, day_regex, year_regex));
            dmy_regex = new Regex ("^%s?((?(day)\\s+)?%s,?)?((?(month)\\s+|(?(day)\\s+|\\s*))%s)?$"
                .printf (day_regex, month_regex, year_regex));
            ymd_regex = new Regex ("^%s?((?(year)\\s+)?%s,?)?((?(month)\\s+|(?(year)\\s+|\\s*))%s)?$"
                .printf (year_regex, month_regex, day_regex));
        } catch (RegexError e) {
            stdout.printf ("Regex Error: %s\n", e.message);
            return;
        }

        mdy_regex.match (str, 0, out match_info);
        if (!match_info.matches ()) {
            dmy_regex.match (str, 0, out match_info);
        }
        if (!match_info.matches ()) {
            ymd_regex.match (str, 0, out match_info);
        }

        if (match_info.matches ()) {
            var year = match_info.fetch_named ("year");
            var month = match_info.fetch_named ("month");
            var day = match_info.fetch_named ("day");

            if (month != null && month != "" &&
                parse_month_name (month) == DateMonth.BAD_MONTH) {
                // Invalid month name
                return;
            } else {
                this.day = day != null && day != ""? (DateDay) int.parse (day) : DateDay.BAD_DAY;
                this.month = month != null && month != ""? parse_month_name (month) : DateMonth.BAD_MONTH;
                this.year = year != null && year != ""? (DateYear) int.parse (year) : DateYear.BAD_YEAR;
            }
        }
    }

    public void clear () {
        day = DateDay.BAD_DAY;
        month = DateMonth.BAD_MONTH;
        year = DateYear.BAD_YEAR;
    }

    public bool valid () {
        return Date.valid_dmy (day, month, year);
    }

    public bool equal (DateUtil date) {
        return day == date.day && month == date.month && year == date.year;
    }

    public Date to_date () {
        var date = Date ();

        date.set_dmy (day, month, year);

        return date;
    }

    private static DateMonth parse_month_name (string text) {
        var name = text.down ();

        if (Regex.match_simple ("^jan(uary)?$", name)) {
            return DateMonth.JANUARY;
        } else if (Regex.match_simple ("^feb(ruary)?$", name)) {
            return DateMonth.FEBRUARY;
        } else if (Regex.match_simple ("^mar(ch)?$", name)) {
            return DateMonth.MARCH;
        } else if (Regex.match_simple ("^apr(il)?$", name)) {
            return DateMonth.APRIL;
        } else if (Regex.match_simple ("^may$", name)) {
            return DateMonth.MAY;
        } else if (Regex.match_simple ("^june?$", name)) {
            return DateMonth.JUNE;
        } else if (Regex.match_simple ("^july?$", name)) {
            return DateMonth.JULY;
        } else if (Regex.match_simple ("^aug(ust)?$", name)) {
            return DateMonth.AUGUST;
        } else if (Regex.match_simple ("^sep(t(ember)?)?$", name)) {
            return DateMonth.SEPTEMBER;
        } else if (Regex.match_simple ("^oct(ober)?$", name)) {
            return DateMonth.OCTOBER;
        } else if (Regex.match_simple ("^nov(ember)?$", name)) {
            return DateMonth.NOVEMBER;
        } else if (Regex.match_simple ("^dec(ember)?$", name)) {
            return DateMonth.DECEMBER;
        } else {
            return DateMonth.BAD_MONTH;
        }
    }

    private static DateDay get_month_last_day (DateMonth month, DateYear year) {
        DateDay last = 31;

        while (!Date.valid_dmy (last, month, year)) {
            last--;
        }

        return last;
    }

    public static bool span_for_text (string text, ref Date start_date, ref Date end_date) {
        Regex span_regex, limit_regex;
        MatchInfo match_info;

        var dt_now = new DateTime.now_local ();
        var date_now = Date ();
        date_now.set_dmy ((DateDay) dt_now.get_day_of_month (),
                          (DateMonth) dt_now.get_month (),
                          (DateYear) dt_now.get_year ());

        var str = text.strip ();

        try {
            var date_regex = "[.,a-zA-Z0-9\\s]+";

            span_regex = new Regex ("^(?:from\\s+)?(?P<start>%s)\\s+to\\s+(?P<end>%s)$"
                .printf (date_regex, date_regex));
            limit_regex = new Regex ("^(?P<pos>before|after)\\s+(?P<date>%s)$"
                .printf (date_regex));
        } catch (RegexError e) {
            stdout.printf ("Regex Error: %s\n", e.message);
            return false;
        }

        span_regex.match (str, 0, out match_info);
        if (match_info.matches ()) {
            var start = DateUtil.from_text (match_info.fetch_named ("start"));
            var end = DateUtil.from_text (match_info.fetch_named ("end"));

            if (start.day == DateDay.BAD_DAY &&
                start.month == DateMonth.BAD_MONTH &&
                start.year == DateYear.BAD_YEAR) {
                return false;
            }

            if (end.day == DateDay.BAD_DAY &&
                end.month == DateMonth.BAD_MONTH &&
                end.year == DateYear.BAD_YEAR) {
                return false;
            }

            if (start.year == DateYear.BAD_YEAR) {
                if (end.year == DateYear.BAD_YEAR) {
                    if (start.month == DateMonth.BAD_MONTH) {
                        if (start.day != DateDay.BAD_DAY &&
                            end.day != DateDay.BAD_DAY &&
                            start.day < end.day) {
                            // *XX - *?X: 19 to 23 ?
                            start.year = date_now.get_year ();
                            end.year = date_now.get_year ();

                            if (end.month == DateMonth.BAD_MONTH) {
                                end.month = date_now.get_month ();
                            }

                            start.month = end.month;
                        }
                    } else {
                        if (end.month == DateMonth.BAD_MONTH) {
                            if (start.day != DateDay.BAD_DAY &&
                                end.day != DateDay.BAD_DAY &&
                                start.day < end.day) {
                                // **X - *XX: Oct 19 to 23
                                end.month = start.month;
                                start.year = date_now.get_year ();
                                end.year = date_now.get_year ();
                            }
                        } else {
                            // ?*X - ?*X: Oct ? to Oct ?
                            if (start.month < end.month) {
                                start.year = date_now.get_year ();
                                end.year = date_now.get_year ();
                            } else {
                                start.year = date_now.get_year () - 1;
                                end.year = date_now.get_year ();
                            }

                            if (start.day == DateDay.BAD_DAY) {
                                start.day = 1;
                            }

                            if (end.day == DateDay.BAD_DAY) {
                                end.day = get_month_last_day (end.month, end.year);
                            }
                        }
                    }
                } else {
                    if (start.month == DateMonth.BAD_MONTH) {
                        if (end.month != DateMonth.BAD_MONTH &&
                            end.day != DateDay.BAD_DAY &&
                            start.day != DateDay.BAD_DAY &&
                            start.day < end.day) {
                            // *XX - ***: 19 to 23 Oct 2014
                            start.month = end.month;
                            start.year = end.year;
                        }
                    } else {
                        if (end.month == DateMonth.BAD_MONTH) {
                            if (end.day == DateDay.BAD_DAY) {
                                // ?*X - XX*: Oct ? to 2014
                                end.day = 31;
                                end.month = DateMonth.DECEMBER;
                                start.year = date_now.get_year ();

                                if (start.day == DateDay.BAD_DAY) {
                                    start.day = 1;
                                }
                            } else {
                                if (start.day != DateDay.BAD_DAY &&
                                    start.day < end.day) {
                                    // **X - *X*: Oct 19 to 23, 2014
                                    end.month = start.month;
                                    start.year = end.year;
                                }
                            }
                        } else {
                            // ?*X - ?**: Oct ? to Oct ?, 2014
                            if (start.month <= end.month) {
                                start.year = end.year;
                            } else {
                                start.year = end.year - 1;
                            }

                            if (start.day == DateDay.BAD_DAY) {
                                start.day = 1;
                            }

                            if (end.day == DateDay.BAD_DAY) {
                                end.day = get_month_last_day (end.month, end.year);
                            }
                        }
                    }
                }
            } else {
                if (end.year == DateYear.BAD_YEAR) {
                    if (start.month == DateMonth.BAD_MONTH) {
                        if (end.month == DateMonth.BAD_MONTH) {
                            if (start.day == DateDay.BAD_DAY &&
                                end.day != DateDay.BAD_DAY) {
                                // XX* - *XX: 2014 to 23
                                start.day = 1;
                                start.month = DateMonth.JANUARY;
                                end.month = date_now.get_month ();
                                end.year = date_now.get_year ();
                            }
                        } else {
                            if (start.day == DateDay.BAD_DAY) {
                                // XX* - ?*X: 2014 to ? Oct
                                start.day = 1;
                                start.month = DateMonth.JANUARY;
                                end.year = date_now.get_year ();

                                if (end.day == DateDay.BAD_DAY) {
                                    end.day = get_month_last_day (end.month, end.year);
                                }
                            }
                        }
                    } else {
                        if (end.month == DateMonth.BAD_MONTH) {
                            if (end.day != DateDay.BAD_DAY) {
                                // ?** - *XX: Oct ?, 2014 to 23
                                end.month = date_now.get_month ();
                                end.year = date_now.get_year ();

                                if (start.day == DateDay.BAD_DAY) {
                                    start.day = 1;
                                }
                            }
                        } else {
                            // ?** - ?*X: Oct ?, 2014 to Oct ?
                            end.year = date_now.get_year ();

                            if (start.day == DateDay.BAD_DAY) {
                                start.day = 1;
                            }

                            if (end.day == DateDay.BAD_DAY) {
                                end.day = get_month_last_day (end.month, end.year);
                            }
                        }
                    }
                } else {
                    if (start.month == DateMonth.BAD_MONTH) {

                        if (end.month == DateMonth.BAD_MONTH) {
                            if (start.day == DateDay.BAD_DAY &&
                                end.day == DateDay.BAD_DAY) {
                                // XX* - XX*: 2014 to 2014
                                start.day = 1;
                                start.month = DateMonth.JANUARY;
                                end.day = 31;
                                end.month = DateMonth.DECEMBER;
                            }
                        } else {
                            if (start.day == DateDay.BAD_DAY) {
                                // XX* - ?**: 2014 to Oct ?, 2014
                                start.month = end.month;

                                if (end.day == DateDay.BAD_DAY) {
                                    end.day = get_month_last_day (end.month, end.year);
                                }
                            }
                        }
                    } else {
                        if (end.month == DateMonth.BAD_MONTH) {
                            if (end.day == DateDay.BAD_DAY) {
                                // ?** - XX*: Oct ?, 2014 to 2014
                                end.month = start.month;

                                if (start.day == DateDay.BAD_DAY) {
                                    start.day = 1;
                                }
                            }
                        } else {
                            // ?** - ?**: Oct ?, 2014 to Oct ?, 2014

                            if (start.day == DateDay.BAD_DAY) {
                                start.day = 1;
                            }

                            if (end.day == DateDay.BAD_DAY) {
                                end.day = get_month_last_day (end.month, end.year);
                            }
                        }
                    }
                }
            }

            if (start.valid () && end.valid () &&
                start.to_date ().compare (end.to_date ()) <= 0) {
                start_date = start.to_date ();
                end_date = end.to_date ();

                return true;
            }

            return false;
        }

        limit_regex.match (str, 0, out match_info);
        if (match_info.matches ()) {
            var pos = match_info.fetch_named ("pos");
            var date = DateUtil.from_text (match_info.fetch_named ("date"));

            if (date.day == DateDay.BAD_DAY &&
                date.month == DateMonth.BAD_MONTH &&
                date.year == DateYear.BAD_YEAR) {
                return false;
            }

            if (!date.valid ()) {
                if (date.month == DateMonth.BAD_MONTH) {
                    if (date.year == DateYear.BAD_YEAR) {
                        date.month = date_now.get_month ();
                    } else {
                        date.month = pos == "before"?
                            DateMonth.JANUARY : DateMonth.DECEMBER;
                    }
                }

                if (date.year == DateYear.BAD_YEAR) {
                    date.year = date_now.get_year ();
                }

                if (date.day == DateDay.BAD_DAY) {
                    date.day = pos == "before"?
                        1 : get_month_last_day (date.month, date.year);
                }
            }

            if (pos == "before") {
                start_date = Date ();
                end_date = date.to_date ();
            } else {
                start_date = date.to_date ();
                end_date = Date ();
            }

            return true;
        }

        var date = DateUtil.from_text (str);
        if (date.valid () ||
            Date.valid_dmy (date.day, date.month, date_now.get_year ())) {
            if (date.year == DateYear.BAD_YEAR) {
                date.year = date_now.get_year ();
            }

            start_date = date.to_date ();
            end_date = date.to_date ();
 
            return true;
        } else if (date.month != DateMonth.BAD_MONTH ||
            date.year != DateYear.BAD_YEAR) {
            var start = Date ();
            var end = Date ();

            if (date.month != DateMonth.BAD_MONTH) {
                if (date.year == DateYear.BAD_YEAR) {
                    date.year = date_now.get_year ();
                }

                date.day = 1;
                start = date.to_date ();

                date.day = get_month_last_day (date.month, date.year);
                end = date.to_date ();
            } else if (date.year != DateYear.BAD_YEAR) {
                date.month = DateMonth.JANUARY;
                date.day = 1;
                start = date.to_date ();

                date.month = DateMonth.DECEMBER;
                date.day = 31;
                end = date.to_date ();
            }

            start_date = start;
            end_date = end;

            return true;
        }

        return false;
    }

}
