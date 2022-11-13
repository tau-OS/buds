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
    [GtkTemplate (ui = "/co/tauos/Buds/window.ui")]
    public class Window : He.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.ListBox contacts_listbox;

        // Contact Info side
        [GtkChild]
        private unowned Gtk.Image contact_image;
        [GtkChild]
        private unowned Gtk.Label contact_name;
        [GtkChild]
        private unowned He.MiniContentBlock phone_block;
        [GtkChild]
        private unowned He.MiniContentBlock email_block;
        [GtkChild]
        private unowned He.MiniContentBlock bday_block;

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
        }

        public Folks.Individual? get_selected_contact () {
            if (selected_row == null)
                return null;
            return ((ContactRow) selected_row).individual;
        }

        public void setup_contact_info () {
            var contact = get_selected_contact ();

            if (contact.avatar != null) {
                contact_image.gicon = contact.avatar;
                contact_image.add_css_class ("person-icon");
                contact_image.set_overflow (Gtk.Overflow.HIDDEN);
            } else {
                contact_image.icon_name = "avatar-default-symbolic";
                contact_image.add_css_class ("person-icon-no-img");
                contact_image.set_overflow (Gtk.Overflow.HIDDEN);
            }
            contact_name.label = contact.display_name;

            if (contact.phone_numbers != null) {
                var phones = "";
                foreach (var num in contact.phone_numbers) {
                    if (contact.phone_numbers.size > 1) {
                        phones += num.get_normalised () + "\n";
                    } else {
                        phones += num.get_normalised ();
                    }
                }
                phone_block.subtitle = phones;
                phone_block.visible = true;
            } else {
                phone_block.visible = false;
            }

            var emails = "";
            foreach (var mail in contact.email_addresses) {
                emails += mail.value;
            }
            if (emails != "") {
                email_block.subtitle = emails;
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
