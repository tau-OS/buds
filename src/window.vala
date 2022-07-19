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
        [GtkChild] private unowned Gtk.ListBox contacts_listbox;

        public Core.Store store = Core.Store.get_default ();

        public Window (Buds.Application app) {
            Object (application: app);

            contacts_listbox.bind_model (store.filter_model, create_row_for_item_cb);
        }

        private Gtk.Widget create_row_for_item_cb (Object obj) {
            var individual = (Folks.Individual) obj;
            var row = new ContactRow (individual);
            return row;
        }
    }
}
