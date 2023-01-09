sources = [
   'application.vala',
   'window.vala',
   'core/store.vala',
   'core/utils.vala',
   'widgets/contact_row.vala'
]

config_file = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf
)

libbismuth_dep = meson.get_compiler('c').find_library('libbismuth', required: false)
deps = [
    dependency('gtk4'),
    dependency('libhelium-1'),
    dependency('libbismuth-1', fallback: [ 'libbismuth', 'libbismuth_dep' ], version: '>=1.0.0'),
    dependency('gee-0.8'),
    dependency('folks'),
    meson.get_compiler('vala').find_library('posix')
]

gnome = import('gnome')

executable(
    meson.project_name(),
	  sources,
    config_file,
	  asresources,
	  vala_args: '--target-glib=2.50',
	  dependencies: deps,
	  install: true,
)
