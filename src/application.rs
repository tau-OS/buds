use crate::{
    action,
    config::{APP_ID, PKGDATADIR, PROFILE, VERSION},
    window::Window,
};
use gtk::{
    gio::{self, ActionGroup, ActionMap, ApplicationFlags, Settings},
    glib::{self, clone},
};
use he::{prelude::*, subclass::prelude::*, AboutWindow, AboutWindowLicenses};
use log::{debug, info};

mod imp {
    use super::*;
    use gtk::{glib::WeakRef, subclass::prelude::*};
    use he::subclass::application::HeApplicationImpl;
    use once_cell::sync::OnceCell;
    use crate::config::APP_ID;

    pub struct Application {
        pub settings: Settings,
        pub window: OnceCell<WeakRef<Window>>,
    }

    impl Default for Application {
        fn default() -> Self {
            Self {
                settings: Settings::new(APP_ID),
                window: OnceCell::<WeakRef<Window>>::default(),
            }
        }
    }

    #[glib::object_subclass]
    impl ObjectSubclass for Application {
        const NAME: &'static str = "Application";
        type Type = super::Application;
        type ParentType = he::Application;
    }

    impl ObjectImpl for Application {}
    impl ApplicationImpl for Application {
        fn activate(&self, app: &Self::Type) {
            debug!("HeApplication<Application>::activate");
            self.parent_activate(app);

            if let Some(window) = self.window.get() {
                let window = window.upgrade().unwrap();
                window.present();
                return;
            }

            let window = Window::new(app);
            self.window
                .set(window.downgrade())
                .expect("Window already set.");

            app.main_window().present();
        }

        fn startup(&self, app: &Self::Type) {
            debug!("HeApplication<Application>::startup");
            self.parent_startup(app);

            // Set icons for shell
            gtk::Window::set_default_icon_name(APP_ID);

            app.setup_actions();
            app.setup_accels();
        }
    }

    impl GtkApplicationImpl for Application {}
    impl HeApplicationImpl for Application {}
}

glib::wrapper! {
    pub struct Application(ObjectSubclass<imp::Application>)
        @extends gio::Application, gtk::Application, he::Application,
        @implements ActionMap, ActionGroup;
}

impl Application {
    pub fn new() -> Self {
        glib::Object::new(&[
            ("application-id", &Some(APP_ID)),
            ("flags", &ApplicationFlags::empty()),
            ("resource-base-path", &Some("/co/tauos/Buds/")),
        ])
        .expect("Application initialization failed...")
    }

    fn setup_actions(&self) {
        action!(
            self,
            "quit",
            clone!(@weak self as app => move |_, _| {
                app.main_window().close();
                app.quit();
            })
        );
        action!(
            self,
            "about",
            clone!(@weak self as app => move |_, _| {
                app.show_about();
            })
        )
    }

    fn setup_accels(&self) {
        self.set_accels_for_action("app.quit", &["<Control>q"]);
        self.set_accels_for_action("app.about", &["<Control>a"]);
    }

    pub fn settings(&self) -> Settings {
        self.imp().settings.clone()
    }

    pub fn main_window(&self) -> Window {
        self.imp().window.get().unwrap().upgrade().unwrap()
    }

    pub fn run(&self) {
        info!("Buds ({})", APP_ID);
        info!("Version: {} ({})", VERSION, PROFILE);
        info!("Datadir: {}", PKGDATADIR);

        ApplicationExtManual::run(self);
    }

    fn show_about(&self) {
        let window = self.active_window().unwrap();
        AboutWindow::builder()
            .transient_for(&window)
            .modal(true)
            .icon_name(APP_ID)
            .app_name("Buds")
            .version(VERSION)
            .developer_names(vec!["Jamie Murphy".into()])
            .copyright_year(2022)
            .license(AboutWindowLicenses::Gplv3)
            .build()
            .present();
    }
}

impl Default for Application {
    fn default() -> Self {
        gio::Application::default()
            .unwrap()
            .downcast::<Application>()
            .unwrap()
    }
}
