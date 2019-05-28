package Mojolicious::Plugin::MultiLanguage;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::Collection 'c';
use HTTP::AcceptLanguage;

our $VERSION = "1.02_006";
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{api_base}   ||= ["/api"];
  $conf->{cookie}     ||= {path => "/"};
  $conf->{languages}  ||= [qw/es fr de zh-tw/];
  $conf->{image_url}  ||= "/images/lang/%s.png";

  state $langs_enabled = c(
    'en', @{$conf->{languages}}
  )->map(sub { lc $_ })->flatten->uniq;

  state $langs_available = c(
    # English
    {
      code    => 'en',
      name    => "English",
      native  => "English",
      index2  => 1,
      index3  => 1,
      rtl     => 0
    },

    # Spanish
    {
      code    => 'es',
      name    => "Spanish",
      native  => "Español",
      index2  => 2,
      index3  => 2,
      rtl     => 0
    },

    # German
    {
      code    => 'de',
      name    => "German",
      native  => "Deutsch",
      index2  => 3,
      index3  => 3,
      rtl     => 0
    },

    # French
    {
      code    => 'fr',
      name    => "French",
      native  => "Français",
      index2  => 4,
      index3  => 4,
      rtl     => 0
    },

    # Portuguese
    {
      code    => 'pt',
      name    => "Portuguese",
      native  => "Português",
      index2  => 5,
      index3  => 5,
      rtl     => 0
    },

    # Italian
    {
      code    => 'it',
      name    => "Italian",
      native  => "Italian",
      index2  => 6,
      index3  => 6,
      rtl     => 0
    },

    # Polish
    {
      code    => 'pl',
      name    => "Polish",
      native  => "Polish",
      index2  => 7,
      index3  => 7,
      rtl     => 0
    },

    # Russian
    {
      code    => 'ru',
      name    => "Russian",
      native  => "Русский",
      index2  => 8,
      index3  => 8,
      rtl     => 0
    },

    # Ukrainian
    {
      code    => 'uk',
      name    => "Ukrainian",
      native  => "Українська",
      index2  => 9,
      index3  => 9,
      rtl     => 0
    },

    # Belarusian
    {
      code    => 'be',
      name    => "Belarusian",
      native  => "Беларускі",
      index2  => 10,
      index3  => 10,
      rtl     => 0
    },

    # Greek
    {
      code    => 'el',
      name    => "Greek",
      native  => "Greek",
      index2  => 11,
      index3  => 11,
      rtl     => 0
    },

    # Turkish
    {
      code    => 'tr',
      name    => "Turkish",
      native  => "Türk",
      index2  => 12,
      index3  => 12,
      rtl     => 0
    },

    # Arabic
    {
      code    => 'ar',
      name    => "Arabic",
      native  => "العربية",
      index2  => 13,
      index3  => 13,
      rtl     => 1
    },

    # Farsi
    {
      code    => 'fa',
      name    => "Farsi",
      native  => "Farsi",
      index2  => 14,
      index3  => 14,
      rtl     => 1
    },

    # Hindi
    {
      code    => 'hi',
      name    => "Hindi",
      native  => "Hindi",
      index2  => 15,
      index3  => 15,
      rtl     => 0
    },

    # Chinese
    {
      code    => 'zh-cn',
      name    => "Chinese (Simplified)",
      native  => "中国",
      index2  => 16,
      index3  => 16,
      rtl     => 0
    },

    {
      code    => 'zh-tw',
      name    => "Chinese (Traditional)",
      native  => "中国",
      index2  => 17,
      index3  => 17,
      rtl     => 0
    },

    # Japanese
    {
      code    => 'ja',
      name    => "Japanese",
      native  => "日本",
      index2  => 18,
      index3  => 18,
      rtl     => 0
    },

    # Korean
    {
      code    => 'ko',
      name    => "Korean",
      native  => "日本",
      index2  => 19,
      index3  => 19,
      rtl     => 0
    }
  )->each(sub { $_->{index1} = 1 });

  # Active languages codes
  $app->helper(lang_codes => sub {
    my ($c) = @_;

    $c->_lang_collection->map(sub { $_->{code} })->to_array;
  });

  # Complete language collection
  $app->helper(lang_collection => sub {
    my ($c) = @_;

    my $default = $c->_lang_default;
    my $lang = $c->stash('lang') || $default;

    $c->_lang_collection->each(sub {
      $_->{select}  = $lang->{code} eq $_->{code} ? 1 : 0;
      $_->{image}   = sprintf $conf->{image_url}, $_->{code};
      $_->{param}   = $_->{code} ne $default->{code} ? $_->{code} : '';
    });
  });

  $app->hook(before_routes => sub {
    my ($c) = @_;

    my $path = $c->req->url->path;
    return if $c->res->code;

    warn "PATH: ", $path->to_string;
    my $api = grep { $path->contains($_) } @{$conf->{api_base}};
    my $lang = $api ? $c->language_api : $c->language_site;

    $c->stash(lang => $lang);
  });

  $app->hook(after_routes => sub {
    my ($c) = @_;

    my $lang = $c->stash('lang');

    $c->res->headers->append("Vary" => "Accept-Language");
    $c->res->headers->content_language($lang->{code});
  });

  # Deletect language for site via url, cookie and headers
  $app->helper(language_site => sub {
    my ($c) = @_;

    my $path = $c->req->url->path;
    my $part = $path->parts->[0] || '';

    my $default = $c->_lang_default;

    my $process = (
      extract   => 0,
      detect    => $default->{code},
      redirect  => 0,
      location  => "/"
    );

    #my ($extract, $detect, $redirect, $location) = (0, $default->{code}, 0, '');

    if ($part eq $default->{code}) {
      warn "Param with default redirect to root\n";
      @process[0, 1, 2, 3] = (1, $part, 1, $path);
      #@process{qw/extract detect/}    = (1, $part);
      #@process{qw/redirect location/} = (1, $path);
    }

    elsif ($c->_lang_verify($part)) {
      warn "Last chance to check param\n";
      @process[0, 1, 2, 3] = (1, $part, 0, $path);
      #@process{qw/extract detect/}    = (1, $part);
      #@process{qw/redirect location/} = (0, $path);
    }

    else {
      warn "None found, continue with default: $path\n";
      my $cookie = $c->_lang_parse_cookie;

      unless ($cookie) {
        my $accept = $c->_lang_parse_accept;

        unless ($accept) {
          warn "Language detect via headers: empty, use default\n";
        }

        elsif ($accept eq $default->{code}) {
          warn "Language detect via headers: set to default\n";
          @process{qw/extract detect/}    = (0, $accept);
          ($redirect, $detect) = (0, $accept);
        }

        else {
          warn "Language detected via header, need redirect\n";
          ($redirect, $detect) = (1, $accept);
        }
      }

      elsif ($cookie eq $default->{code}) {
        warn "Language detected via cookie: set to default\n";
        ($redirect, $detect) = (0, $cookie);
      }

      else {
        warn "Language detected via cookie, need redirect\n";
        ($redirect, $detect) = (1, $cookie);
      }
    }

    if ($process[0]) {
      shift @{$path->parts};
      $path->trailing_slash(0);
    }

    if ($result[2]) {
      $c->redirect_to("/$process[3]");
      return undef;
    }

    my $lang = $c->_lang_lookup($process[1]);

    $c->app->log->debug("Detect language '$lang->{code}' via site");
    $c->cookie(language => $lang->{code}, $conf->{cookie});

    return $lang;
  });

  # Deletect language for api via headers only
  $app->helper(language_api => sub {
    my ($c) = @_;

    my $default = $c->_lang_default;

    # Skip CORS requests with default language
    return $default if $c->req->method eq 'OPTIONS';

    my $detect = $c->_lang_parse_accept;

    my $lang = $c->_lang_verify($detect)
      ? $c->_lang_lookup($detect) : $default;

    $c->app->log->debug("Detect language '$lang->{code}' via API");

    return $lang;
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

  $app->helper(_lang_verify => sub {
    my ($c, $code) = @_;

    return 0 unless $code and $code =~ /^[a-z]{2}(-[a-z]{2})?$/;
    $c->_lang_collection->grep(sub { $code eq $_->{code} })->size;
  });

  $app->helper(_lang_parse_cookie => sub {
    my ($c) = @_;

    my $code = $c->cookie('language');
    $c->_lang_verify($code) ? $code : '';
  });

  $app->helper(_lang_parse_accept => sub {
    my ($c) = @_;

    my $header = $c->req->headers->accept_language;
    my $accept_language = HTTP::AcceptLanguage->new($header);

    my $code = $accept_language->match(@{$c->lang_codes});
    $c->_lang_verify($code) ? $code : '';
  });

# $app->helper(_lang_finish => sub {
#   my ($c, $lang) = @_;
#
#   $c->stash(lang => $lang);
#
#   $c->res->headers->append("Vary" => "Accept-Language");
#   $c->res->headers->content_language($lang->{code});
#
#   return $lang;
# });

  my $mojo_url_for = *Mojolicious::Controller::url_for{CODE};

  my $lang_url_for = sub {
    my $c = shift;

    my $url = $c->$mojo_url_for(@_);
    return $url if $url->is_abs;

    # Discard target if present
    shift if (@_ % 2 && !ref $_[0]) || (@_ > 1 && ref $_[-1]);

    # Unveil params
    my %params = @_ == 1 ? %{$_[0]} : @_;

    my $lang = $c->stash('lang');

    my $code = $params{language} || $lang->{code};

    return $url unless $code;

    my $path = $url->path || [];

    unless ($path->[0]) {
      $path->parts([$code])
    }

    else {
      unshift @{$path->parts}, $code
        unless $c->lang_collection->grep(sub { $path->contains("/$_->{code}") })->size;
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
