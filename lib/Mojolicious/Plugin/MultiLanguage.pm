package Mojolicious::Plugin::MultiLanguage;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::Collection 'c';
use HTTP::AcceptLanguage;

## no critic
our $VERSION = "1.05_006";
$VERSION = eval $VERSION;
## use critic

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{cookie}     //= {path => "/"};
  $conf->{languages}  //= [qw/es fr de zh-tw/];
  $conf->{api_under}  //= ["/api"];

  state $langs_enabled = c(
    'en', @{$conf->{languages}}
  )->map(sub { lc $_ })->flatten->uniq;

  state $langs_available = c(
    # English
    {
      code    => 'en',
      name    => "English",
      native  => "English",
      dir     => 'ltr',
      index2  => 1,
      index3  => 1,
    },

    # Spanish
    {
      code    => 'es',
      name    => "Spanish",
      native  => "Español",
      dir     => 'ltr',
      index2  => 2,
      index3  => 2,
    },

    # German
    {
      code    => 'de',
      name    => "German",
      native  => "Deutsch",
      dir     => 'ltr',
      index2  => 3,
      index3  => 3,
    },

    # French
    {
      code    => 'fr',
      name    => "French",
      native  => "Français",
      dir     => 'ltr',
      index2  => 4,
      index3  => 4,
    },

    # Portuguese
    {
      code    => 'pt-br',
      name    => "Portuguese",
      native  => "Português",
      dir     => 'ltr',
      index2  => 5,
      index3  => 5,
    },

    # Italian
    {
      code    => 'it',
      name    => "Italian",
      native  => "italiano",
      dir     => 'ltr',
      index2  => 6,
      index3  => 6,
    },

    # Polish
    {
      code    => 'pl',
      name    => "Polish",
      native  => "Polskie",
      dir     => 'ltr',
      index2  => 7,
      index3  => 7,
    },

    # Russian
    {
      code    => 'ru',
      name    => "Russian",
      native  => "Русский",
      dir     => 'ltr',
      index2  => 8,
      index3  => 8,
    },

    # Ukrainian
    {
      code    => 'uk',
      name    => "Ukrainian",
      native  => "Українська",
      dir     => 'ltr',
      index2  => 9,
      index3  => 9,
    },

    # Belarusian
    {
      code    => 'be',
      name    => "Belarusian",
      native  => "Беларускі",
      dir     => 'ltr',
      index2  => 10,
      index3  => 10,
    },

    # Greek
    {
      code    => 'el',
      name    => "Greek",
      native  => "Ελληνικά",
      dir     => 'ltr',
      index2  => 11,
      index3  => 11,
    },

    # Turkish
    {
      code    => 'tr',
      name    => "Turkish",
      native  => "Türk",
      dir     => 'ltr',
      index2  => 12,
      index3  => 12,
    },

    # Arabic
    {
      code    => 'ar',
      name    => "Arabic",
      native  => "العربية",
      dir     => 'rtl',
      index2  => 13,
      index3  => 13,
    },

    # Farsi
    {
      code    => 'fa',
      name    => "Farsi",
      native  => "हिंदी",
      dir     => 'rtl',
      index2  => 14,
      index3  => 14,
    },

    # Hindi
    {
      code    => 'hi',
      name    => "Hindi",
      native  => "हिंदी",
      dir     => 'ltr',
      index2  => 15,
      index3  => 15,
    },

    # Chinese
    {
      code    => 'zh-cn',
      name    => "Chinese (Simplified)",
      native  => "中国",
      dir     => 'ltr',
      index2  => 16,
      index3  => 16,
    },

    {
      code    => 'zh-tw',
      name    => "Chinese (Traditional)",
      native  => "中国",
      dir     => 'ltr',
      index2  => 17,
      index3  => 17,
    },

    # Japanese
    {
      code    => 'ja',
      name    => "Japanese",
      native  => "日本",
      dir     => 'ltr',
      index2  => 18,
      index3  => 18,
    },

    # Korean
    {
      code    => 'ko',
      name    => "Korean",
      native  => "日本",
      dir     => 'ltr',
      index2  => 19,
      index3  => 19,
    }
  )->each(sub { $_->{index1} = 1 });

  #
  # Helpers
  #

  # Active languages codes
  $app->helper(langs => sub {
    my ($c) = @_;

    $c->_lang_collection->map(sub { $_->{code} });
  });

  # Complete language collection
  $app->helper(languages => sub {
    my ($c) = @_;

    my $language = $c->stash('language');

    $c->_lang_collection->each(sub {
      $_->{active} = $_->{code} eq $language->{code} ? 1 : 0;
    });
  });

  #
  # Private helpers
  #

  # Detect language for site via url, cookie or headers
  $app->helper(_lang_detect_site => sub {
    my ($c, $path) = @_;

    $c->stash(route_lang => 1);
    my $default = $c->_lang_default;
    my $param = $path->parts->[0] // '';

    my @flags = (0, $default->{code}, 0, "/");

    unless ($param) {
      my $cookie = $c->cookie('lang');

      unless ($cookie) {
        my $accept = $c->_lang_accept_language;

        unless ($accept) {
          $app->log->debug("Unknown Accept-Language");
        }

        elsif ($accept eq $default->{code}) {
          @flags[1] = ($accept);
        }

        elsif ($c->_lang_exists($accept)) {
          @flags[1, 2, 3] = ($accept, 1, "/$accept");
        }

        else {
          $app->log->debug("Bad Accept-Language: $accept");
        }
      }

      elsif ($cookie eq $default->{code}) {
        @flags[1] = ($cookie);
      }

      elsif ($c->_lang_exists($cookie)) {
        @flags[1, 2, 3] = ($cookie, 1, "/$cookie");
      }

      else {
        $app->log->debug("Bad Cookie language: $cookie");
      }
    }

    elsif ($param eq $default->{code}) {
      @flags[0, 1, 2, 3] = (1, $param, 1, $path);
    }

    elsif ($c->_lang_exists($param)) {
      @flags[0, 1, 2, 3] = (1, $param, 0, $path);
    }

    else {
      $app->log->debug("No language detected");
    }

    if ($flags[0]) {
      shift @{$path->parts};
      $path->trailing_slash(0);
    }

    my $language = $c->_lang_lookup($flags[1]);
    $c->cookie(lang => $language->{code}, $conf->{cookie});

    $c->redirect_to($flags[3]) and return undef if $flags[2];

    return $language;
  });

  # Detetect language for api via headers only
  $app->helper(_lang_detect_api => sub {
    my ($c) = @_;

    $c->stash(route_lang => 0);
    my $default = $c->_lang_default;

    # Skip CORS requests with default language
    return $default if $c->req->method eq 'OPTIONS';

    my $detect = $c->_lang_accept_language;

    my $language = $c->_lang_exists($detect)
      ? $c->_lang_lookup($detect) : $default;

    return $language;
  });

  $app->helper(_lang_default => sub { $langs_available->first });

  $app->helper(_lang_lookup => sub {
    my ($c, $code) = @_;

    $langs_available->grep(sub { lc $code eq $_->{code} })->first
      or die "Language code '$code' does not exists\n";
  });

  $app->helper(_lang_collection => sub {
    my ($c) = @_;

    $langs_enabled->map(sub { $c->_lang_lookup($_) });
  });

  $app->helper(_lang_exists => sub {
    my ($c, $code) = @_;

    return 0 unless $code and $code =~ /^[a-z]{2}(-[a-z]{2})?$/;
    $c->_lang_collection->grep(sub { $code eq $_->{code} })->size;
  });

  $app->helper(_lang_parse_cookie => sub {
    my ($c) = @_;

    my $code = $c->cookie('lang');
    $c->_lang_exists($code) ? $code : '';
  });

  $app->helper(_lang_accept_language => sub {
    my ($c) = @_;

    my $header = $c->req->headers->accept_language;
    HTTP::AcceptLanguage->new($header)->match(@{$c->langs});
  });

  #
  # Hooks
  #

  $app->hook(before_routes => sub {
    my ($c) = @_;

    return if $c->res->code;

    my $path = $c->req->url->path;
    my $is_api = grep { $path->contains($_) } @{$conf->{api_under}};

    return unless my $language = $is_api
      ? $c->_lang_detect_api : $c->_lang_detect_site($path);

    $app->log->debug("Detect language '$language->{code}'");

    $c->stash(language => $language, english => $c->_lang_default);
    $c->stash(languages => $c->languages->to_array);
  });

  $app->hook(after_render => sub {
    my ($c) = @_;

    return unless my $language = $c->stash('language');

    $c->res->headers->append('Vary' => "Accept-Language");
    $c->res->headers->content_language($language->{code});
  });

  #
  # Reimplement 'url_for' helper
  #

  my $mojo_url_for = *Mojolicious::Controller::url_for{CODE};

  my $lang_url_for = sub {
    my $c = shift;

    my $url = $c->$mojo_url_for(@_);
    return $url if $url->is_abs;
    return $url unless $c->stash('route_lang');

    my %params = @_ == 1 ? %{$_[0]} : @_;

    my $languages = $c->stash('languages');
    my $language  = $c->stash('language');
    my $english   = $c->stash('english');

    my $code = $params{lang} // $language->{code};
    return $url if $code eq $english->{code};

    my $path = $url->path // [];

    unless ($path->[0]) {
      $path->parts([$code]);
    }

    else {
      my $exists = grep {
        $path->contains(sprintf "/%s", $_->{code})
      } @$languages;

      unshift @{$path->parts}, $code unless $exists;
    }

    return $url;
  };

  {
    no strict 'refs';
    no warnings 'redefine';

    *Mojolicious::Controller::url_for = $lang_url_for;
  }
}

1;
