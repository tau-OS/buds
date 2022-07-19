/* application.vala
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
    public class Application : He.Application {
        public Application () {
            Object (
                application_id: Config.APP_ID,
                flags: ApplicationFlags.FLAGS_NONE,
                resource_base_path: "/co/tauos/Buds"
            );
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences_action },
                { "quit", this.quit }
            };
            this.add_action_entries (action_entries, this);
            this.set_accels_for_action ("app.quit", {"<primary>q"});
        }

        public override void activate () {
            base.activate ();
            var win = this.active_window;
            if (win == null) {
                win = new Buds.Window (this);
            }
            win.present ();
        }


        private void on_about_action () {
            string[] developers = { "Jamie Murphy" };
            string[] translators = { "Jamie Murphy" };
            new He.AboutWindow (this.active_window,
                            "Buds" + Config.NAME_SUFFIX,
                            Config.APP_ID,
                            Config.VERSION,
                            Config.APP_ID,
                            "",
                            "",
                            "",
                            translators,
                            developers,
                            2022,
                            He.AboutWindow.Licenses.GPLv3,
                            He.Colors.BLUE).present ();
        }

        private void on_preferences_action () {
            message ("nya");
        }
    }
}

public static int main (string[] args) {
    var app = new Buds.Application ();
    return app.run (args);
}
