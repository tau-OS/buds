/* window.vala
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

namespace Buds {
    [GtkTemplate (ui = "/com/fyralabs/Buds/window.ui")]
    public class Window : He.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.ListBox contacts_listbox;
        [GtkChild]
        private unowned He.Avatar contact_image;
        [GtkChild]
        private unowned Gtk.Label contact_name;
        [GtkChild]
        private unowned He.MiniContentBlock phone_block;
        [GtkChild]
        private unowned He.MiniContentBlock email_block;
        [GtkChild]
        private unowned He.MiniContentBlock bday_block;
        [GtkChild]
        private unowned He.AppBar info_title;
        [GtkChild]
        private unowned Bis.Album album;
        [GtkChild]
        private unowned He.SideBar listgrid;
        [GtkChild]
        private unowned Gtk.Box info;
        [GtkChild]
        private unowned Gtk.SearchEntry search_entry;
        [GtkChild]
        private unowned Gtk.Stack stack;
        [GtkChild]
        private unowned He.EmptyPage empty_page;
        [GtkChild]
        private unowned He.Button phone_button;
        [GtkChild]
        private unowned He.Button email_button;
        [GtkChild]
        public unowned Gtk.Overlay about_overlay;
        [GtkChild]
        private unowned He.Button edit_button;
        [GtkChild]
        private unowned He.OverlayButton add_button;
        [GtkChild]
        private unowned Gtk.MenuButton menu_button;

        public Core.Store store;

        private ContactRow? _selected_row = null;
        public ContactRow? selected_row {
            get {
                return _selected_row;
            } set {
                _selected_row = value;
            }
        }

        public Window (Buds.Application app, Core.Store store_instance) {
            Object (application : app);

            store = store_instance;

            contacts_listbox.bind_model (store.filter_model, create_row_for_item_cb);

            info_title.back_button.clicked.connect (() => {
                if (album.folded) {
                    album.set_visible_child (listgrid);
                }
            });

            search_entry.search_changed.connect (() => {
                update_search_filter ();
            });

            empty_page.action_button.visible = false;

            phone_button.clicked.connect (() => {
                string ext_txt = phone_block.subtitle;

                // Put this ext_txt in clipboard
                var display = Gdk.Display.get_default ();
                unowned var clipboard = display.get_clipboard ();
                clipboard.set_text (ext_txt);
            });

            email_button.clicked.connect (() => {
                string ext_txt = email_block.subtitle;

                // Put this ext_txt in clipboard
                var display = Gdk.Display.get_default ();
                unowned var clipboard = display.get_clipboard ();
                clipboard.set_text (ext_txt);
            });

            edit_button.clicked.connect (() => {
                show_edit_contact_dialog ();
            });

            add_button.clicked.connect (() => {
                show_add_contact_dialog ();
            });

            edit_button.visible = false;
            menu_button.get_popover ().has_arrow = false;
        }

        private void show_error_dialog (string title, string message) {
            var error_dialog = new He.Dialog (this, title, message);
            error_dialog.icon = "dialog-error-symbolic";
            error_dialog.present ();
        }

        private void update_search_filter () {
            var search_term = search_entry.text.strip ();
            store.update_query (search_term);
        }

        private void show_add_contact_dialog () {
            var dialog = new He.Dialog (this, _("Add Contact"), _("Create a new contact"), "", null, null);

            string? selected_avatar_path = null;

            var avatar_button = new Gtk.Button () {
                width_request = 96,
                height_request = 96,
                halign = Gtk.Align.CENTER
            };
            avatar_button.add_css_class ("circular");

            var avatar_image = new He.Avatar (96, "", "", false);
            avatar_button.set_child (avatar_image);

            avatar_button.clicked.connect (() => {
                var file_dialog = new Gtk.FileDialog () {
                    title = _("Select Contact Picture"),
                    modal = true
                };

                var filter = new Gtk.FileFilter ();
                filter.set_filter_name ("Image Files");
                filter.add_mime_type ("image/*");

                var filters = new ListStore (typeof (Gtk.FileFilter));
                filters.append (filter);
                file_dialog.filters = filters;

                file_dialog.open.begin (this, null, (obj, res) => {
                    try {
                        var file = file_dialog.open.end (res);
                        if (file != null) {
                            selected_avatar_path = file.get_path ();
                            avatar_image.image = "file://" + selected_avatar_path;
                        }
                    } catch (Error e) {
                        // User cancelled
                    }
                });
            });

            var given_name_entry = new Gtk.Entry ();
            given_name_entry.placeholder_text = _("First Name");
            given_name_entry.add_css_class ("text-field");

            var family_name_entry = new Gtk.Entry ();
            family_name_entry.placeholder_text = _("Last Name");
            family_name_entry.add_css_class ("text-field");

            var phone_entry = new Gtk.Entry ();
            phone_entry.placeholder_text = _("Phone Number");
            phone_entry.add_css_class ("text-field");

            var email_entry = new Gtk.Entry ();
            email_entry.placeholder_text = _("Email Address");
            email_entry.add_css_class ("text-field");

            dialog.add (avatar_button);
            dialog.add (given_name_entry);
            dialog.add (family_name_entry);
            dialog.add (phone_entry);
            dialog.add (email_entry);

            var add_button = new He.Button ("", _("Add")) {
                is_pill = true
            };

            dialog.cancel_button.clicked.connect (() => {
                dialog.hide_dialog ();
            });

            add_button.clicked.connect (() => {
                var given_name = given_name_entry.text;
                var family_name = family_name_entry.text;
                var phone = phone_entry.text;
                var email = email_entry.text;

                if (given_name == "" && family_name == "") {
                    return;
                }

                store.add_contact.begin (given_name, family_name, phone, email, null, selected_avatar_path, (obj, res) => {
                    try {
                        store.add_contact.end (res);
                        dialog.hide_dialog ();
                    } catch (Error e) {
                        warning ("Failed to add contact: %s", e.message);
                        string error_message;
                        error_message = _("No local address book is available. You may need to set up a local contact store in System Settings.");
                        show_error_dialog (_("Unable to Add Contact"), error_message);
                        dialog.hide_dialog ();
                    }
                });
            });

            dialog.primary_button = add_button;
            dialog.present ();
        }

        private void show_edit_contact_dialog () {
            var contact = get_selected_contact ();
            if (contact == null)return;

            var dialog = new He.Dialog (this, _("Edit Contact"), _("Modify contact details"), "", null, null);

            string? selected_avatar_path = null;

            var avatar_button = new Gtk.Button () {
                width_request = 96,
                height_request = 96,
                halign = Gtk.Align.CENTER
            };
            avatar_button.add_css_class ("circular");

            var avatar_image = new He.Avatar (96, "", "", false);

            // Set current avatar if exists
            if (contact.avatar != null) {
                avatar_image.image = "file://" + contact.avatar.to_string ();
            } else {
                avatar_image.text = contact.display_name;
            }

            avatar_button.set_child (avatar_image);

            avatar_button.clicked.connect (() => {
                var file_dialog = new Gtk.FileDialog () {
                    title = _("Select Contact Picture"),
                    modal = true
                };

                var filter = new Gtk.FileFilter ();
                filter.set_filter_name ("Image Files");
                filter.add_mime_type ("image/*");

                var filters = new ListStore (typeof (Gtk.FileFilter));
                filters.append (filter);
                file_dialog.filters = filters;

                file_dialog.open.begin (this, null, (obj, res) => {
                    try {
                        var file = file_dialog.open.end (res);
                        if (file != null) {
                            selected_avatar_path = file.get_path ();
                            avatar_image.image = "file://" + selected_avatar_path;
                        }
                    } catch (Error e) {
                        // User cancelled
                    }
                });
            });

            var given_name_entry = new Gtk.Entry ();
            given_name_entry.placeholder_text = _("First Name");
            given_name_entry.add_css_class ("text-field");

            var family_name_entry = new Gtk.Entry ();
            family_name_entry.placeholder_text = _("Last Name");
            family_name_entry.add_css_class ("text-field");

            var phone_entry = new Gtk.Entry ();
            phone_entry.placeholder_text = _("Phone Number");
            phone_entry.add_css_class ("text-field");

            var email_entry = new Gtk.Entry ();
            email_entry.placeholder_text = _("Email Address");
            email_entry.add_css_class ("text-field");

            if (contact.structured_name != null) {
                given_name_entry.text = contact.structured_name.given_name ?? "";
                family_name_entry.text = contact.structured_name.family_name ?? "";
            }

            if (contact.phone_numbers != null && contact.phone_numbers.size > 0) {
                var first_phone = contact.phone_numbers.to_array ()[0];
                phone_entry.text = first_phone.get_normalised ();
            }

            if (contact.email_addresses != null && contact.email_addresses.size > 0) {
                var first_email = contact.email_addresses.to_array ()[0];
                email_entry.text = first_email.value;
            }

            dialog.add (avatar_button);
            dialog.add (given_name_entry);
            dialog.add (family_name_entry);
            dialog.add (phone_entry);
            dialog.add (email_entry);

            var save_button = new He.Button ("", _("Save")) {
                is_pill = true
            };

            dialog.cancel_button.clicked.connect (() => {
                dialog.hide_dialog ();
            });

            save_button.clicked.connect (() => {
                var given_name = given_name_entry.text;
                var family_name = family_name_entry.text;
                var phone = phone_entry.text;
                var email = email_entry.text;

                if (given_name == "" && family_name == "") {
                    return;
                }

                store.update_contact.begin (contact, given_name, family_name, phone, email, null, selected_avatar_path, (obj, res) => {
                    try {
                        store.update_contact.end (res);
                        setup_contact_info ();
                        dialog.hide_dialog ();
                    } catch (Error e) {
                        warning ("Failed to update contact: %s", e.message);
                        string error_message;
                        error_message = _("This contact is synced from a service like Google or iCloud and can only be edited in that service's settings.");
                        show_error_dialog (_("Unable to Save Changes"), error_message);
                        dialog.hide_dialog ();
                    }
                });
            });

            dialog.primary_button = save_button;
            dialog.present ();
        }

        private Gtk.Widget create_row_for_item_cb (Object obj) {
            var individual = (Folks.Individual) obj;
            var row = new ContactRow (individual, false);
            return row;
        }

        [GtkCallback]
        private void item_activated (Gtk.ListBoxRow listbox_row) {
            var row = (ContactRow) listbox_row;

            if (selected_row != null && selected_row != row) {
                ((ContactRow) selected_row).selected = false;
            }

            row.selected = !row.selected;
            if (row.selected) {
                selected_row = row;
                setup_contact_info ();
                var contact = get_selected_contact ();
                if (contact != null && store.can_edit_contact (contact)) {
                    edit_button.visible = true;
                } else {
                    edit_button.visible = false;
                }
            } else {
                selected_row = null;
                edit_button.visible = false;
            }

            album.set_visible_child (info);
            stack.set_visible_child_name ("info");
        }

        public Folks.Individual? get_selected_contact () {
            if (selected_row == null)
                return null;
            return ((ContactRow) selected_row).individual;
        }

        public void setup_contact_info () {
            var contact = get_selected_contact ();

            contact_image.text = contact.display_name;
            contact_image.image = null;

            if (contact.avatar != null) {
                contact_image.text = null;
                contact_image.image = "file://" + contact.avatar.to_string ();
            } else {
                contact_image.text = contact.display_name;
                contact_image.image = null;
            }
            contact_name.label = contact.display_name;

            if (contact.phone_numbers != null && contact.phone_numbers.size > 0) {
                string[] phones = {};
                phone_block.subtitle = "";
                foreach (var num in contact.phone_numbers) {
                    phones += num.get_normalised ();
                }
                for (int i = 0; i < phones.length; i++) {
                    if (i == 0) {
                        phone_block.subtitle = phones[i];
                    } else {
                        phone_block.subtitle += "\n" + phones[i];
                    }
                }
                phone_block.visible = true;
            } else {
                phone_block.visible = false;
            }

            if (contact.email_addresses != null && contact.email_addresses.size > 0) {
                string[] emails = {};
                email_block.subtitle = "";
                foreach (var mail in contact.email_addresses) {
                    emails += mail.value;
                }
                for (int j = 0; j < emails.length; j++) {
                    if (j == 0) {
                        email_block.subtitle = emails[j];
                    } else {
                        email_block.subtitle += "\n" + emails[j];
                    }
                }
                email_block.visible = true;
            } else {
                email_block.visible = false;
            }

            var bday = contact.birthday;

            if (bday != null) {
                bday_block.subtitle = bday.format ("%x");
                bday_block.visible = true;
            } else {
                bday_block.visible = false;
            }
        }
    }
}