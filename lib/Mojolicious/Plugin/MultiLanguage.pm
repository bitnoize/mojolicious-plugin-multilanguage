package Mojolicious::Plugin::MultiLanguage;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::Collection 'c';
use HTTP::AcceptLanguage;

our $VERSION = "1.02_004";
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  state $langs_enabled = c(
    'en', @{$conf->{languages} ||= [qw/es fr de zh-tw/]}
  )->flatten->uniq;

  state $langs_available = c(
    # English
    {
      code    => 'en',
      name    => "English",
      native  => "English",
      index1  => 1,
      index2  => 1,
      rtl     => 0
    },

    # Spanish
    {
      code    => 'es',
      name    => "Spanish",
      native  => "Español",
      index1  => 2,
      index2  => 2,
      rtl     => 0
    },

    # German
    {
      code    => 'de',
      name    => "German",
      native  => "Deutsch",
      index1  => 3,
      index2  => 3,
      rtl     => 0
    },

    # French
    {
      code    => 'fr',
      name    => "French",
      native  => "Français",
      index1  => 4,
      index2  => 4,
      rtl     => 0
    },

    # Italian
    {
      code    => 'it',
      name    => "Italian",
      native  => "Italian",
      index1  => 5,
      index2  => 5,
      rtl     => 0
    },

    # Portuguese
    {
      code    => 'pt',
      name    => "Portuguese",
      native  => "Português",
      index1  => 6,
      index2  => 6,
      rtl     => 0
    },

    # Dutch
    {
      code    => 'nl',
      name    => "Danish",
      native  => "Danish",
      index1  => 7,
      index2  => 7,
      rtl     => 0
    },

    # Czech
    {
      code    => 'cs',
      name    => "Czech",
      native  => "Czech",
      index1  => 8,
      index2  => 8,
      rtl     => 0
    },

    # Swedish
    {
      code    => 'sv',
      name    => "Swedish",
      native  => "Swedish",
      index1  => 9,
      index2  => 9,
      rtl     => 0
    },

    # Norwegian
    {
      code    => 'no',
      name    => "Norwegian",
      native  => "Norwegian",
      index1  => 10,
      index2  => 10,
      rtl     => 0
    },

    # Finnish
    {
      code    => 'fi',
      name    => "Finnish",
      native  => "Finnish",
      index1  => 11,
      index2  => 11,
      rtl     => 0
    },

    # Danish
    {
      code    => 'da',
      name    => "Danish",
      native  => "Danish",
      index1  => 12,
      index2  => 12,
      rtl     => 0
    },

    # Polish
    {
      code    => 'pl',
      name    => "Polish",
      native  => "Polish",
      index1  => 13,
      index2  => 13,
      rtl     => 0
    },

    # Croatian
    {
      code    => 'hr',
      name    => "Croatian",
      native  => "Croatian",
      index1  => 14,
      index2  => 14,
      rtl     => 0
    },

    # Serbian
    {
      code    => 'sr',
      name    => "Serbian",
      native  => "Serbian",
      index1  => 15,
      index2  => 15,
      rtl     => 0
    },

    # Bulgarian
    {
      code    => 'bg',
      name    => "Bulgarian",
      native  => "Bulgarian",
      index1  => 16,
      index2  => 16,
      rtl     => 0
    },

    # Albanian
    {
      code    => 'sq',
      name    => "Albanian",
      native  => "Albanian",
      index1  => 17,
      index2  => 17,
      rtl     => 0
    },

    # Russian
    {
      code    => 'ru',
      name    => "Russian",
      native  => "Русский",
      index1  => 18,
      index2  => 18,
      rtl     => 0
    },

    # Ukrainian
    {
      code    => 'uk',
      name    => "Ukrainian",
      native  => "Українська",
      index1  => 19,
      index2  => 19,
      rtl     => 0
    },

    # Belarusian
    {
      code    => 'be',
      name    => "Belarusian",
      native  => "Беларускі",
      index1  => 20,
      index2  => 20,
      rtl     => 0
    },

    # Romanian
    {
      code    => 'ro',
      name    => "Romanian",
      native  => "Romanian",
      index1  => 21,
      index2  => 21,
      rtl     => 0
    },

    # Turkish
    {
      code    => 'tr',
      name    => "Turkish",
      native  => "Türk",
      index1  => 22,
      index2  => 22,
      rtl     => 0
    },

    # Greek
    {
      code    => 'el',
      name    => "Greek",
      native  => "Greek",
      index1  => 23,
      index2  => 23,
      rtl     => 0
    },

    # Arabic
    {
      code    => 'ar',
      name    => "Arabic",
      native  => "العربية",
      index1  => 24,
      index2  => 24,
      rtl     => 1
    },

    # Farsi
    {
      code    => 'fa',
      name    => "Farsi",
      native  => "Farsi",
      index1  => 25,
      index2  => 25,
      rtl     => 1
    },

    # Hindi
    {
      code    => 'hi',
      name    => "Hindi",
      native  => "Hindi",
      index1  => 26,
      index2  => 26,
      rtl     => 0
    },

    # Chinese
    {
      code    => 'zh-cn',
      name    => "Chinese (Simplified)",
      native  => "中国",
      index1  => 27,
      index2  => 27,
      rtl     => 0
    },

    {
      code    => 'zh-tw',
      name    => "Chinese (Traditional)",
      native  => "中国",
      index1  => 3,
      index2  => 3,
      rtl     => 28
    },

    # Japanese
    {
      code    => 'ja',
      name    => "Japanese",
      native  => "日本",
      index1  => 30,
      index2  => 30,
      rtl     => 0
    },

    # Korean
    {
      code    => 'ko',
      name    => "Korean",
      native  => "日本",
      index1  => 31,
      index2  => 31,
      rtl     => 0
    }
  );

  # Default language is hardcoded to english
  $app->helper('lang.default' => sub { $langs_available->first });

  # Try to find language via code, with exception
  $app->helper('lang.lookup' => sub {
    my ($c, $code) = @_;

    $langs_available->grep(sub { $code eq $_->{code} })->first
      or die "Language code '$code' not found\n";
  });

  # Active languages collection
  $app->helper('lang.collection' => sub {
    my ($c) = @_;

    $langs_enabled->map(sub { $c->lang->lookup($_) });
  });

  # Try to verify language via code, safely
  $app->helper('lang.verify' => sub {
    my ($c, $code) = @_;

    return 0 unless $code;
    #return 0 unless $code and $code =~ /^[a-z-]{2,6}$/;
    $c->lang->collection->grep(sub { $code eq $_->{code} })->size;
  });

  # Active languages codes
  $app->helper('lang.codes' => sub {
    my ($c) = @_;

    $c->lang->collection->map(sub { $_->{code} })->to_array;
  });

  # Deletect language for site via url, cookie and headers
  $app->helper('lang.detect_site' => sub {
    my ($c, $field) = @_;

    my $default = $c->lang->default;
    my $param = $c->param($field ||= 'language') || '';

    return $default if $c->req->method eq 'OPTIONS';

    my ($redirect, $detect);

    # URL param is not set
    if ($param eq '') {
      # Try parse language via cookie
      my $cookie = $c->lang->parse_cookie;

      # Cookie is empty
      unless ($cookie) {
        # Try parse language via accept
        my $accept = $c->lang->parse_accept;

        # Accept is empty
        unless ($accept) {
          ($redirect, $detect) = (0, $default->{code})
        }

        # Accept is set to default language
        elsif ($accept eq $default->{code}) {
          ($redirect, $detect) = (0, $default->{code})
        }

        else {
          ($redirect, $detect) = (1, $accept)
        }
      }

      # Cookie is set to default language
      elsif ($cookie eq $default->{code}) {
        ($redirect, $detect) = (0, $cookie);
      }

      # Any other language is ok
      else {
        ($redirect, $detect) = (1, $cookie);
      }
    }

    elsif ($param eq $default->{code}) {
      ($redirect, $detect) = (1, '');
    }

    # Any other language is ok
    else {
      ($redirect, $detect) = (0, $param);
    }

    if ($redirect) {
      $c->redirect_to($field => $detect);
      return undef;
    }

    my $lang = $c->lang->verify($detect)
      ? $c->lang->lookup($detect) : $default;

    $c->app->log->debug("Detect language '$lang->{code}' via site");
    $c->cookie($field => $lang->{code}, {path => "/"});

    $c->lang->finish($lang);
  });

  # Deletect language for api via headers only
  $app->helper('lang.detect_api' => sub {
    my ($c, $field) = @_;

    my $default = $c->lang->default;
    my $detect = $c->lang->parse_accept;

    my $lang = $c->lang->verify($detect)
      ? $c->lang->lookup($detect) : $default;

    $c->app->log->debug("Detect language '$lang->{code}' via api");

    $c->lang->finish($lang);
  });

  # Store language data
  $app->helper('lang.finish' => sub {
    my ($c, $lang) = @_;

    die "Bad language on finish" unless $lang and ref $lang;

    $c->stash(lang => $lang);

    $c->res->headers->append("Vary" => "Accept-Language");
    $c->res->headers->content_language($lang->{code});

    return $lang;
  });

  $app->helper('lang.parse_cookie' => sub {
    my ($c) = @_;

    my $code = $c->cookie('language');
    $c->lang->verify($code) ? $code : '';
  });

  $app->helper('lang.parse_accept' => sub {
    my ($c) = @_;

    my $header = $c->req->headers->accept_language;
    my $accept_language = HTTP::AcceptLanguage->new($header);

    my $code = $accept_language->match(@{$c->lang->codes});
    $c->lang->verify($code) ? $code : '';
  });

  $app->routes->add_type(langs => $app->lang->codes);
}

1;

__END__

  $app->helper(accept_language => sub {
    my ($c) = @_;

    return $c->default_language if $c->req->method eq 'OPTIONS';

    my $header = $c->req->headers->accept_language || "";
    my $accept_language = HTTP::AcceptLanguage->new($header);

    my $code = $accept_language->match(@{$app->langs});
    return $c->default_language unless $code;

    my $lang = $app->language($code);
    return $c->default_language unless $lang;

    $c->app->log->debug("Accept Language '$lang->{code}'");

    $c->res->headers->append("Vary" => "Accept-Language");
    $c->res->headers->content_language($code);

    return $lang;
  });


