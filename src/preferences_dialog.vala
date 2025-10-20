namespace Buds {
    [GtkTemplate (ui = "/com/fyralabs/Buds/preferences.ui")]
    public class PreferencesDialog : He.SettingsWindow {
        [GtkChild]
        private unowned He.SettingsList backends_list;
        [GtkChild]
        private unowned He.SettingsRow sort_order_row;

        private Core.Store store;
        private GLib.Settings settings;

        public PreferencesDialog (Core.Store store) {
            Object ();
            this.store = store;
            this.settings = new GLib.Settings ("com.fyralabs.Buds");
        }

        construct {
            warning ("PreferencesDialog construct");
            warning ("backends_list is null: %s", (backends_list == null).to_string ());
            warning ("backends_list type: %s", backends_list.get_type ().name ());

            setup_sort_order_row ();

            // Wait a bit for backends to be fully loaded
            Timeout.add (100, () => {
                populate_backends ();
                return false;
            });
        }

        private void setup_sort_order_row () {
            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            button_box.add_css_class ("segmented-button");

            var current_order = settings.get_string ("sort-order");

            var name_button = new Gtk.ToggleButton () {
                label = _("Name")
            };

            var surname_button = new Gtk.ToggleButton () {
                label = _("Surname"),
                group = name_button
            };

            // Set the active button based on current setting
            if (current_order == "surname") {
                surname_button.active = true;
            } else {
                name_button.active = true;
            }

            name_button.toggled.connect (() => {
                if (name_button.active) {
                    settings.set_string ("sort-order", "name");
                }
            });

            surname_button.toggled.connect (() => {
                if (surname_button.active) {
                    settings.set_string ("sort-order", "surname");
                }
            });

            button_box.append (name_button);
            button_box.append (surname_button);

            sort_order_row.add (button_box);
        }

        private void populate_backends () {
            debug ("populate_backends called");

            // Clear existing children
            foreach (var child in backends_list.children) {
                backends_list.remove (child);
            }

            // Also try to load backends that might not be enabled yet
            store.backend_store.load_backends.begin ((obj, res) => {
                try {
                    store.backend_store.load_backends.end (res);

                    debug ("Backends loaded, enabled_backends count: %u", store.backend_store.enabled_backends.size);

                    // Get all loaded backends
                    var backend_names = new Gee.HashSet<string> ();

                    foreach (var backend in store.backend_store.enabled_backends.values) {
                        debug ("Found enabled backend: %s", backend.name);
                        backend_names.add (backend.name);
                    }

                    if (backend_names.size == 0) {
                        debug ("No backends found, adding defaults");
                        backend_names.add ("eds");
                    }

                    foreach (var backend_name in backend_names) {
                        debug ("Adding backend row: %s", backend_name);
                        add_backend_row (backend_name);
                    }
                } catch (Error e) {
                    warning ("Failed to load backends: %s", e.message);
                    // Add at least EDS as fallback
                    add_backend_row ("eds");
                }
            });
        }

        private void add_backend_row (string backend_name) {
            warning ("Creating row for backend: %s", backend_name);

            var row = new He.SettingsRow () {
                title = get_backend_display_name (backend_name),
                visible = true
            };

            var switch_widget = new Gtk.Switch () {
                valign = Gtk.Align.CENTER,
                active = store.is_backend_enabled (backend_name),
                visible = true
            };

            switch_widget.notify["active"].connect (() => {
                store.set_backend_enabled (backend_name, switch_widget.active);
            });

            row.add (switch_widget);

            backends_list.add (row);

            // He.SettingsList adds children in a timeout, but we're adding after construction
            // So we need to manually add to the internal list
            var list_child = backends_list.get_last_child ();
            if (list_child != null && list_child is Gtk.ListBox) {
                ((Gtk.ListBox) list_child).append (row);
                warning ("Row manually appended to internal ListBox");
            }

            warning ("Row added to backends_list, children count: %u", backends_list.children.length ());
        }

        private string get_backend_display_name (string backend_name) {
            switch (backend_name) {
            case "eds":
                return "Local Contacts";
            default:
                return backend_name.up (1) + backend_name.substring (1);
            }
        }
    }
}