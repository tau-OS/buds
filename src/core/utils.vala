namespace Buds.Core {
    public class QueryFilter : Gtk.Filter {
        public Folks.Query query { get; construct; }

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
            Object (query: query);

            query.notify.connect (on_query_notify);
        }

        private void on_query_notify (Object object, ParamSpec pspec) {
            changed (Gtk.FilterChange.DIFFERENT);
        }

        public override bool match (GLib.Object? item) {
            unowned var individual = item as Folks.Individual;
            if (individual == null) {
                return false;
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
            return a.is_favourite? Gtk.Ordering.SMALLER : Gtk.Ordering.LARGER;

            // Both are (non-)favourites: sort by either first name or surname
            unowned var a_name = sort_on_surname? try_get_surname (a) : a.display_name;
            unowned var b_name = sort_on_surname? try_get_surname (b) : b.display_name;

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
