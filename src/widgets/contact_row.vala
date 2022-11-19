/* widgets/contact_row.vala
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
    public class ContactRow : Gtk.ListBoxRow {
        public Folks.Individual individual { get; construct; }

        private Gtk.Label title = new Gtk.Label ("");
        private Gtk.Image image = new Gtk.Image ();
        public bool selected { get; set; }

        public ContactRow (Folks.Individual individual, bool selected) {
            Object (individual: individual, selected: selected);

            generate_row ();

            individual.notify.connect (on_contact_changed_cb);
        }

        private void generate_row () {
            title.label = individual.display_name;
            title.add_css_class ("cb-title");

            image.pixel_size = 32;
            image.add_css_class ("person-icon");

            if (individual.avatar != null) {
                image.gicon = individual.avatar;
                image.add_css_class ("person-icon");
                image.set_overflow (Gtk.Overflow.HIDDEN);
            } else {
                image.icon_name = "avatar-default-symbolic";
                image.add_css_class ("person-icon-no-img");
                image.set_overflow (Gtk.Overflow.HIDDEN);
            }

            var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            main_box.append (image);
            main_box.append (title);

            main_box.set_parent (this);
            main_box.add_css_class ("mini-content-block");
        }

        private void on_contact_changed_cb (Object obj, ParamSpec pspec) {
            generate_row ();
            changed ();
        }
    }
}
