/* core/utils.vala
 *
 * Copyright 2022 Fyra Labs
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Buds.Core {
    public class QueryFilter : Gtk.Filter {
        private Folks.Query _query;
        public Folks.Query query {
            get {
                return _query;
            }
            set {
                if (_query != null) {
                    _query.notify.disconnect (on_query_notify);
                }
                _query = value;
                if (_query != null) {
                    _query.notify.connect (on_query_notify);
                }
                changed (Gtk.FilterChange.DIFFERENT);
            }
        }

        private uint _min_strength = 0;
        public uint min_strength {
            get {
                return _min_strength;
            }
            set {
                if (value == _min_strength) {
                    return;
                }

                _min_strength = value;
                changed (Gtk.FilterChange.DIFFERENT);
            }
        }

        public QueryFilter (Folks.Query query) {
            Object ();
            this.query = query;
        }

        private void on_query_notify (Object object, ParamSpec pspec) {
            changed (Gtk.FilterChange.DIFFERENT);
        }

        public override bool match (GLib.Object? item) {
            unowned var individual = item as Folks.Individual;
            if (individual == null) {
                return false;
            }

            // Filter out contacts without structured name and not favorites
            if (individual.structured_name == null && !individual.is_favourite) {
                return false;
            }

            // If there's no search query, show all valid contacts
            if (query.match_fields == null) {
                return true;
            }

            return query.is_match (individual) > min_strength;
        }

        public override Gtk.FilterMatch get_strictness () {
            return Gtk.FilterMatch.SOME;
        }
    }

    public class IndividualSorter : Gtk.Sorter {
        // User changeable later :)
        private bool sort_on_surname = false;

        public IndividualSorter () {}

        public override Gtk.Ordering compare (Object? item1, Object? item2) {
            unowned var a = item1 as Folks.Individual;
            if (a == null)
                return Gtk.Ordering.SMALLER;

            unowned var b = item2 as Folks.Individual;
            if (b == null)
                return Gtk.Ordering.LARGER;

            // Always prefer favourites over non-favourites.
            if (a.is_favourite != b.is_favourite)
                return a.is_favourite ? Gtk.Ordering.SMALLER : Gtk.Ordering.LARGER;

            // Both are (non-)favourites: sort by either first name or surname
            unowned var a_name = sort_on_surname ? try_get_surname (a) : a.display_name;
            unowned var b_name = sort_on_surname ? try_get_surname (b) : b.display_name;

            int names_cmp = a_name.collate (b_name);
            if (names_cmp != 0)
                return Gtk.Ordering.from_cmpfunc (names_cmp);

            // Since we want total ordering, compare uuids as a last resort
            return Gtk.Ordering.from_cmpfunc (strcmp (a.id, b.id));
        }

        private unowned string try_get_surname (Folks.Individual indiv) {
            if (indiv.structured_name != null && indiv.structured_name.family_name != "")
                return indiv.structured_name.family_name;

            // Fall back to the display_name
            return indiv.display_name;
        }

        public override Gtk.SorterOrder get_order () {
            return Gtk.SorterOrder.TOTAL;
        }
    }
}