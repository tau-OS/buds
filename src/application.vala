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
                flags: ApplicationFlags.FLAGS_NONE
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

        protected override void startup () {
            Gdk.RGBA accent_color = { 0 };
            accent_color.parse("#56BFA6");
            default_accent_color = He.Color.from_gdk_rgba(accent_color);

            resource_base_path = "/co/tauos/Buds";

            base.startup ();

            new Buds.Window (this);
        }

        protected override void activate () {
            active_window?.present ();
        }

        private void on_about_action () {
            string[] developers = { "Lains" };
            new He.AboutWindow (
                this.active_window,
                "Buds" + Config.NAME_SUFFIX,
                "co.tauos.Buds",
                Config.VERSION,
                "co.tauos.Buds",
                "",
                "",
                "",
                {},
                developers,
                2022,
                He.AboutWindow.Licenses.GPLv3,
                He.Colors.MINT
            ).present ();
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
