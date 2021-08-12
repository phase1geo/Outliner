project('com.github.phase1geo.outliner', ['vala', 'c'],
    version : '1.5.1',
    license: 'GPL-3.0'
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

gnome = import('gnome')
i18n = import('i18n')

gresource = gnome.compile_resources(
    'outliner-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
)

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h',
]

sources = files()

subdir('data')
subdir('po')
subdir('src')
subdir('tests')

gtk_dep = dependency('gtk+-3.0')

if gtk_dep.version().version_compare('>=3.22.0')
  add_project_arguments(['--define=GTK322'], language: 'vala')
endif

# Add the math and Markdown libraries
cc = meson.get_compiler('c')
math_dep    = cc.find_library('m', required: false)
libmarkdown = cc.find_library('markdown', required: true)

# Figure out if Granite will support some features
granite = dependency('granite', version: '>=5.5.0', required: true)

add_project_arguments([
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi')
    ],
    language: 'vala',
)

dependencies = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('cairo'),
    dependency('gee-0.8'),
    granite,
    dependency('gtk+-3.0'),
    dependency('libxml-2.0'),
    dependency('webkit2gtk-4.0'),
    dependency('libhandy-1'),
    libmarkdown,
    math_dep
]

e = executable('com.github.phase1geo.outliner',
    sources,
    gresource,
    c_args: c_args,
    dependencies: dependencies,
    vala_args: [
        meson.source_root() + '/vapi/libmarkdown.vapi'
    ],
    install : true
)

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')
