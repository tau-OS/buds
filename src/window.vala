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
        private unowned He.DisclosureButton phone_button;
        [GtkChild]
        private unowned He.DisclosureButton email_button;

        public Core.Store store = Core.Store.get_default ();

        private ContactRow? _selected_row = null;
        public ContactRow? selected_row {
            get {
                return _selected_row;
            } set {
                _selected_row = value;
            }
        }

        public Window (Buds.Application app) {
            Object (application: app);

            contacts_listbox.bind_model (store.filter_model, create_row_for_item_cb);
            contacts_listbox.set_filter_func (filter_function);
            contacts_listbox.set_header_func (header_function);
            contacts_listbox.set_sort_func (sort_function);

            info_title.back_button.clicked.connect (() => {
                if (album.folded) {
                    album.set_visible_child (listgrid);
                }
            });

            search_entry.search_changed.connect (() => {
                contacts_listbox.invalidate_filter ();
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
            } else {
                selected_row = null;
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

            if (contact.phone_numbers != null) {
                string[] phones = {};
                phone_block.subtitle = "";
                int i;
                foreach (var num in contact.phone_numbers) {
                    phones += num.get_normalised ();
                }
                for (i = 0; i <= contact.phone_numbers.size; i++) {
                    if (i == contact.phone_numbers.size) {
                        phone_block.subtitle += phones[i];
                    } else if (i != contact.phone_numbers.size) {
                        phone_block.subtitle += "\n" + phones[i];
                    }
                }
                phone_block.visible = true;
            } else {
                phone_block.visible = false;
            }

            if (contact.email_addresses != null) {
                string[] emails = {};
                email_block.subtitle = "";
                int j;
                foreach (var mail in contact.email_addresses) {
                    emails += mail.value;
                }
                for (j = 0; j <= contact.email_addresses.size; j++) {
                    if (j == contact.email_addresses.size) {
                        email_block.subtitle += emails[j];
                    } else if (j != contact.email_addresses.size) {
                        email_block.subtitle += "\n" + emails[j];
                    }
                }
                email_block.visible = true;
            } else {
                email_block.visible = false;
            }

            var bday = contact.birthday;

            if (bday != null) {
                bday_block.subtitle = "\n" + bday.format ("%x");
                bday_block.visible = true;
            } else {
                bday_block.visible = false;
            }
        }

        [CCode (instance_pos = -1)]
        private bool filter_function (Gtk.ListBoxRow row) {
            var individual = ((Buds.ContactRow) row).individual;

            if (individual.structured_name == null && !individual.is_favourite) {
                return false;
            }

            var search_term = search_entry.text.down ();

            if (search_term in individual.display_name.down ()) {
                return true;
            }

            return false;
        }

        private void header_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow? row2) {
            var name1 = ((Buds.ContactRow) row1).individual.structured_name;
            Folks.StructuredName name2 = null;
            if (row2 != null) {
                name2 = ((Buds.ContactRow) row2).individual.structured_name;
            }
    
            string header_string = null;
            if (name1 != null) {
                if (name1.family_name != "" && name1.family_name.@get (0).isalpha ()) {
                    header_string = name1.family_name.substring (0, 1).up ();
                } else if (name1.given_name != "" && name1.given_name.@get (0).isalpha ()) {
                    header_string = name1.given_name.substring (0, 1).up ();
                } else {
                    header_string = _("#");
                }
            } else if (name2 != null) {
                header_string = _("#");
            }
    
            if (name2 != null) {
                if (name2.family_name != "") {
                    if (name2.family_name.substring (0, 1).up () == header_string || !name2.family_name.@get (0).isalpha ()) {
                        return;
                    }
                } else if (name2.given_name != "") {
                    if (name2.given_name.substring (0, 1).up () == header_string || !name2.given_name.@get (0).isalpha ()) {
                        return;
                    }
                }
            }
    
            if (header_string != null) {
                var header_label = new Gtk.Label (header_string) {
                    halign = Gtk.Align.START,
                    margin_start = 6
                };
                header_label.add_css_class ("heading");
                header_label.add_css_class ("dim-label");
                row1.set_header (header_label);
            }
        }

        [CCode (instance_pos = -1)]
        private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
            var name1 = ((Buds.ContactRow) row1).individual.structured_name;
            var name2 = ((Buds.ContactRow) row2).individual.structured_name;

            if (name1 != null) {
                if (name2 == null) {
                    return -1;
                } else if (name1.family_name.@get (0).isalpha ()) {
                    if (name2.family_name == "" || !name2.family_name.@get (0).isalpha ()) {
                        if (name2.given_name.@get (0).isalpha ()) {
                            return name1.family_name.collate (name2.given_name);
                        } else {
                            return -1;
                        }
                    } else {
                        return name1.family_name.collate (name2.family_name);
                    }
                } else if (name2.family_name.@get (0).isalpha ()) {
                    if (name1.given_name.@get (0).isalpha ()) {
                        return name1.given_name.collate (name2.family_name);
                    } else {
                        return 1;
                    }
                }
            } else if (name2 != null) {
                return 1;
            }

            var displayname1 = ((Buds.ContactRow) row1).individual.display_name;
            var displayname2 = ((Buds.ContactRow) row2).individual.display_name;
            return displayname1.collate (displayname2);
        }
    }
}
