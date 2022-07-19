icondir = join_paths(get_option('datadir'), 'icons/hicolor')

install_data(
  '@0@.svg'.format(app_id),
  install_dir: icondir / 'hicolor' / 'scalable' / 'apps'
)

install_data(
  'co.tauos.Buds-symbolic.svg',
  install_dir: icondir / 'hicolor' / 'symbolic' / 'apps',
  rename: '@0@-symbolic.svg'.format(app_id)
)
