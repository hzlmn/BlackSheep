from setuptools import setup, Extension


def readme():
    with open('README.md') as f:
        return f.read()


COMPILE_ARGS = ['-O3']


setup(name='blacksheep',
      version='0.0.7',
      description='Fast HTTP Server/Client microframework for Python asyncio',
      long_description=readme(),
      long_description_content_type='text/markdown',
      classifiers=[
          'Development Status :: 3 - Alpha',
          'License :: OSI Approved :: MIT License',
          'Programming Language :: Python :: 3.7',
          'Operating System :: OS Independent',
          'Framework :: AsyncIO'
      ],
      url='https://github.com/RobertoPrevato/BlackSheep',
      author='Roberto Prevato',
      author_email='roberto.prevato@gmail.com',
      keywords='BlackSheep web framework',
      platforms=['*nix'],
      license='MIT',
      packages=['blacksheep',
                'blacksheep.server',
                'blacksheep.server.files',
                'blacksheep.server.res',
                'blacksheep.client'],
      ext_modules=[
          Extension('blacksheep.url',
                    ['blacksheep/url.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.exceptions',
                    ['blacksheep/exceptions.c'],
                    extra_compile_args=COMPILE_ARGS),
          
          Extension('blacksheep.options',
                    ['blacksheep/options.c'],
                    extra_compile_args=COMPILE_ARGS),
          
          Extension('blacksheep.headers',
                    ['blacksheep/headers.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.cookies',
                    ['blacksheep/cookies.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.contents',
                    ['blacksheep/contents.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.messages',
                    ['blacksheep/messages.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.scribe',
                    ['blacksheep/scribe.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.baseapp',
                    ['blacksheep/baseapp.c'],
                    extra_compile_args=COMPILE_ARGS),

          Extension('blacksheep.connection',
                    ['blacksheep/connection.c'],
                    extra_compile_args=COMPILE_ARGS)
      ],
      install_requires=[
          'httptools',
          'uvloop',
          'certifi',
          'cchardet'
      ],
      include_package_data=True,
      zip_safe=False)
