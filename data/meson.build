desktop_file = i18n.merge_file(
  	input: application_id + '.desktop.in',
  	output: application_id + '.desktop',
  	type: 'desktop',
  	po_dir: '../po',
  	install: true,
  	install_dir: join_paths(get_option('datadir'), 'applications')
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  	test('Validate desktop file', desktop_utils,
    		args: [desktop_file]
  	)
endif

appstream_file = i18n.merge_file(
  	input: application_id + '.appdata.xml.in',
  	output: application_id + '.appdata.xml',
  	po_dir: '../po',
  	install: true,
  	install_dir: join_paths(get_option('datadir'), 'appdata')
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  	test('Validate appstream file', appstream_util,
    		args: ['validate', appstream_file]
  	)
endif

install_data(
	application_id + '.gschema.xml',
  	install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  	test('Validate schema file', compile_schemas,
    		args: ['--strict', '--dry-run', meson.current_source_dir()]
  	)
endif

blueprints = custom_target(
  'blueprints',
  input: files(
    'ui/window.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

asresources = gnome.compile_resources(
  'as-resources',
  'resources.gresource.xml',
  source_dir: meson.current_build_dir(),
  dependencies: blueprints,
  c_name: 'as',
  install_dir: get_option('datadir') / meson.project_name(),
)

subdir('icons')
