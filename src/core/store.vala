/* core/store.vala
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
    public class Store : Object {
        public Folks.IndividualAggregator aggregator { get; private set; }
        public Folks.BackendStore backend_store {
            get {
                return aggregator.backend_store;
            }
        }

        private ListStore _address_books = new GLib.ListStore (typeof (Folks.PersonaStore));
        public ListModel address_books {
            get {
                return _address_books;
            }
        }

        // Base list model, TODO make these just ListModels
        private GLib.ListStore _base_model = new ListStore (typeof (Folks.Individual));
        public GLib.ListModel base_model {
            get {
                return _base_model;
            }
        }

        // Sorting list model
        public Gtk.SortListModel sort_model { get; private set; }
        public IndividualSorter sorter { get; private set; }

        // Filtering list model
        public Gtk.FilterListModel filter_model { get; private set; }
        public QueryFilter filter { get; private set; }

        public Gtk.SingleSelection selection { get; private set; }

        construct {
            // Setup Backends
            var backend_store = Folks.BackendStore.dup ();
            // TODO: its 3am but i need to impleent ListModel
            foreach (var backend in backend_store.enabled_backends.values) {
                foreach (var persona_store in backend.persona_stores.values) {
                    _address_books.append (persona_store);
                }
            }
            backend_store.backend_available.connect ((backend) => {
                foreach (var persona_store in backend.persona_stores.values) {
                    _address_books.append (persona_store);
                }
            });

            // Setup Individual Aggregator
            aggregator = Folks.IndividualAggregator.dup_with_backend_store (backend_store);
            aggregator.individuals_changed_detailed.connect (on_individuals_changed_detailed_cb);
            aggregator.prepare.begin ();
        }

        public Store () {
            // TODO, maybe put this somewhere else
            string[] filtered_fields = Folks.Query.MATCH_FIELDS_NAMES;
            foreach (unowned var field in Folks.Query.MATCH_FIELDS_ADDRESSES) {
                filtered_fields += field;
            }
            var query = new Folks.SimpleQuery ("", filtered_fields);

            sorter = new IndividualSorter ();
            sort_model = new Gtk.SortListModel (base_model, sorter);
            filter = new QueryFilter (query);
            filter_model = new Gtk.FilterListModel (sort_model, filter);
            selection = new Gtk.SingleSelection (filter_model);
            selection.autoselect = false;
        }

        private void on_individuals_changed_detailed_cb (Gee.MultiMap<Folks.Individual?, Folks.Individual?> changes) {
            var to_add = new GenericArray<unowned Folks.Individual> ();

            foreach (var individual in changes.get_keys ()) {
                if (individual != null) {
                    uint pos = 0;
                    if (_base_model.find (individual, out pos)) {
                        _base_model.remove (pos);
                    } else {
                        debug ("Tried to remove individual '%s', but could't find it", individual.display_name);
                    }
                }

                foreach (var new_i in changes[individual]) {
                    if (new_i != null) {
                        to_add.add (new_i);
                    }
                }
            }

            debug ("Inviduals changed. %d were added", to_add.length);

            foreach (unowned var indiv in to_add) {
                if (indiv.personas.size == 0) {
                  to_add.remove_fast (indiv);
                } else {
                    indiv.notify.connect ((obj, pspec) => {
                        unowned var prop_name = pspec.get_name ();
                        if (prop_name != "display-name" && prop_name != "is-favourite") {
                            return;
                        }

                        uint pos;
                        if (_base_model.find (obj, out pos)) {
                            _base_model.items_changed (pos, 1, 1);
                        }
                    });
                }
            }
            _base_model.splice (base_model.get_n_items (), 0, (Object[]) to_add.data);
        }

        private static GLib.Once<Store> instance;
        public static unowned Store get_default () {
            return instance.once (() => { return new Store (); });
        }
    }
}
