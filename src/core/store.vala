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
        public Folks.BackendStore backend_store { get; private set; }

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

        private Folks.SimpleQuery _query;

        public void update_query (string search_term) {
            string[] filtered_fields = Folks.Query.MATCH_FIELDS_NAMES;
            foreach (unowned var field in Folks.Query.MATCH_FIELDS_ADDRESSES) {
                filtered_fields += field;
            }
            _query = new Folks.SimpleQuery (search_term, filtered_fields);
            filter.query = _query;
        }

        construct {
            // Setup Backends
            backend_store = Folks.BackendStore.dup ();
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

            prepare_aggregator.begin ();
        }

        private async void prepare_aggregator () {
            try {
                yield aggregator.prepare ();

                debug ("Aggregator prepared successfully");
            } catch (Error e) {
                warning ("Failed to prepare aggregator: %s", e.message);
            }
        }

        public Store () {
            // TODO, maybe put this somewhere else
            string[] filtered_fields = Folks.Query.MATCH_FIELDS_NAMES;
            foreach (unowned var field in Folks.Query.MATCH_FIELDS_ADDRESSES) {
                filtered_fields += field;
            }
            _query = new Folks.SimpleQuery ("", filtered_fields);

            sorter = new IndividualSorter ();
            sort_model = new Gtk.SortListModel (base_model, sorter);
            filter = new QueryFilter (_query);
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

        public async void add_contact (string given_name, string family_name, string? phone = null, string? email = null, DateTime? birthday = null, string? avatar_path = null) throws Error {
            var primary_store = get_primary_store ();
            if (primary_store == null) {
                throw new IOError.NOT_FOUND ("No local address book is available. You may need to set up a local contact store in System Settings.");
            }

            var details = new HashTable<string, Value?> (str_hash, str_equal);

            var full_name_value = Value (typeof (string));
            var full_name = (family_name != "" ? family_name + " " : "") + given_name;
            full_name_value.set_string (full_name);
            details.insert ("full-name", full_name_value);

            var structured_name = new Folks.StructuredName (family_name, given_name, null, null, null);
            var structured_name_value = Value (typeof (Folks.StructuredName));
            structured_name_value.set_object (structured_name);
            details.insert ("structured-name", structured_name_value);

            if (phone != null && phone != "") {
                var phone_set = new Gee.HashSet<Folks.PhoneFieldDetails> ();
                var phone_details = new Folks.PhoneFieldDetails (phone);
                phone_set.add (phone_details);
                var phone_value = Value (typeof (Gee.Set));
                phone_value.set_object (phone_set);
                details.insert ("phone-numbers", phone_value);
            }

            if (email != null && email != "") {
                var email_set = new Gee.HashSet<Folks.EmailFieldDetails> ();
                var email_details = new Folks.EmailFieldDetails (email);
                email_set.add (email_details);
                var email_value = Value (typeof (Gee.Set));
                email_value.set_object (email_set);
                details.insert ("email-addresses", email_value);
            }

            if (birthday != null) {
                var bday_value = Value (typeof (DateTime));
                bday_value.set_boxed (birthday);
                details.insert ("birthday", bday_value);
            }

            if (avatar_path != null && avatar_path != "") {
                var avatar_file = File.new_for_path (avatar_path);
                var avatar_icon = new FileIcon (avatar_file);
                var avatar_value = Value (typeof (LoadableIcon));
                avatar_value.set_object (avatar_icon);
                details.insert ("avatar", avatar_value);
            }

            yield aggregator.add_persona_from_details (null, primary_store, details);
        }

        public async void update_contact (Folks.Individual individual, string given_name, string family_name, string? phone = null, string? email = null, DateTime? birthday = null, string? avatar_path = null) throws Error {
            // Check if any of the individual's personas are writeable
            bool has_writeable_persona = false;
            foreach (var persona in individual.personas) {
                if (persona.store.can_add_personas == Folks.MaybeBool.TRUE ||
                    persona.store.can_remove_personas == Folks.MaybeBool.TRUE) {
                    has_writeable_persona = true;
                    break;
                }
            }

            if (!has_writeable_persona) {
                throw new IOError.NOT_SUPPORTED ("This contact is synced from a service like Google or iCloud and can only be edited in that service's settings.");
            }

            var full_name = (family_name != "" ? family_name + " " : "") + given_name;
            if (individual is Folks.NameDetails) {
                var structured_name = new Folks.StructuredName (family_name, given_name, null, null, null);
                yield ((Folks.NameDetails) individual).change_structured_name (structured_name);
                yield ((Folks.NameDetails) individual).change_full_name (full_name);
            }

            if (individual is Folks.PhoneDetails) {
                var phone_set = new Gee.HashSet<Folks.PhoneFieldDetails> ();
                if (phone != null && phone != "") {
                    phone_set.add (new Folks.PhoneFieldDetails (phone));
                }
                yield ((Folks.PhoneDetails) individual).change_phone_numbers (phone_set);
            }

            if (individual is Folks.EmailDetails) {
                var email_set = new Gee.HashSet<Folks.EmailFieldDetails> ();
                if (email != null && email != "") {
                    email_set.add (new Folks.EmailFieldDetails (email));
                }
                yield ((Folks.EmailDetails) individual).change_email_addresses (email_set);
            }

            if (individual is Folks.BirthdayDetails && birthday != null) {
                yield ((Folks.BirthdayDetails) individual).change_birthday (birthday);
            }

            if (individual is Folks.AvatarDetails && avatar_path != null && avatar_path != "") {
                var avatar_file = File.new_for_path (avatar_path);
                var avatar_icon = new FileIcon (avatar_file);
                yield ((Folks.AvatarDetails) individual).change_avatar (avatar_icon);
            }
        }

        public bool can_edit_contact (Folks.Individual individual) {
            foreach (var persona in individual.personas) {
                if (persona.store.can_add_personas == Folks.MaybeBool.TRUE ||
                    persona.store.can_remove_personas == Folks.MaybeBool.TRUE) {
                    return true;
                }
            }
            return false;
        }

        public async void ensure_local_store () throws Error {
            var eds_backend = backend_store.dup_backend_by_name ("eds");
            if (eds_backend == null) {
                throw new IOError.NOT_FOUND ("Evolution Data Server backend not available");
            }

            yield eds_backend.prepare ();

            // Check if we already have a local address book
            bool has_local = false;
            foreach (var persona_store in eds_backend.persona_stores.values) {
                if (persona_store.can_add_personas == Folks.MaybeBool.TRUE) {
                    has_local = true;
                    break;
                }
            }

            if (!has_local) {
                debug ("No local address book found, creating one...");
                // EDS will automatically create a default local address book on first use
            }
        }

        public void set_backend_enabled (string backend_name, bool enabled) {
            try {
                if (enabled) {
                    backend_store.enable_backend (backend_name);
                } else {
                    backend_store.disable_backend (backend_name);
                }
            } catch (Error e) {
                warning ("Failed to %s backend '%s': %s", enabled ? "enable" : "disable", backend_name, e.message);
            }
        }

        public bool is_backend_enabled (string backend_name) {
            return backend_name in backend_store.enabled_backends;
        }

        private Folks.PersonaStore? get_primary_store () {
            for (uint i = 0; i < _address_books.get_n_items (); i++) {
                var store = (Folks.PersonaStore) _address_books.get_item (i);
                if (store.can_add_personas == Folks.MaybeBool.TRUE) {
                    return store;
                }
            }
            return null;
        }

        private static GLib.Once<Store> instance;
        public static unowned Store get_default () {
            return instance.once (() => { return new Store (); });
        }
    }
}