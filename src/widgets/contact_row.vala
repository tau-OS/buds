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
    public class ContactRow : He.MiniContentBlock {
        private new Gtk.ListBoxRow parent {
            get {
                return ((Gtk.ListBoxRow) get_parent ());
            }
        }

        public Folks.Individual individual { get; construct; }

        public ContactRow (Folks.Individual individual) {
            Object (individual: individual);

            title = individual.display_name;
            // TODO button
            // TODO avatar

            individual.notify.connect (on_contact_changed_cb);
        }

        private void on_contact_changed_cb (Object obj, ParamSpec pspec) {
            title = individual.display_name;

            // HeMiniContentBlock does not implement ListBoxRow
            parent.changed ();
        }
    }
}
