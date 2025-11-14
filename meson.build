 project('com.github.phase1geo.outliner', ['vala', 'c'],
    version : '1.7.0',
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

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

sources = files()

subdir('data')
subdir('po')
subdir('src')
subdir('tests')

# Add the math and Markdown libraries
cc = meson.get_compiler('c')
math_dep    = cc.find_library('m', required: false)
libmarkdown = cc.find_library('markdown', required: true)

add_project_arguments([
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
        '--disable-warnings'
    ],
    language: 'vala',
)

add_project_arguments(['-w'], language: 'c')

dependencies = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('cairo'),
    dependency('gee-0.8'),
    dependency('granite-7'),
    dependency('gtk4'),
    dependency('libxml-2.0'),
    dependency('webkitgtk-6.0'),
    libmarkdown,
    math_dep
]

e = executable('com.github.phase1geo.outliner',
    sources,
    config_file,
    gresource,
    dependencies: dependencies,
    vala_args: [
        meson.project_source_root() + '/vapi/libmarkdown.vapi'
    ],
    install : true
)

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')
