project(
    'com.fyralabs.Buds',
    ['c', 'vala'],
    version: '0.1.0',
    meson_version: '>= 0.59.0',
    default_options: [ 'warning_level=2', ],
)

application_id = 'com.fyralabs.Buds'

if get_option('development')
  app_id = 'com.fyralabs.Buds'
  name_suffix = ' (Development)'
else
  app_id = 'com.fyralabs.Buds'
  name_suffix = ''
endif

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('NAME_SUFFIX', name_suffix)
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('APP_SETTINGS', application_id + '.Settings')
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Blueprint
subproject('blueprint-compiler')
add_project_arguments(
    '--gresourcesdir', meson.current_build_dir() / 'data',
    language: ['vala']
)
#

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
