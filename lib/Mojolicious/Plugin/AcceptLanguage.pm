package Mojolicious::Plugin::AcceptLanguage;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::Collection 'c';
use HTTP::AcceptLanguage;

our $VERSION = "1.02_001";
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  #
  # Attrs
  #

  $app->attr(languages => sub { c(
    {
      code    => 'en',
      name    => "English",
      native  => "English",
      index   => 1,
      sort    => 1,
      rtl     => 0
    },

    {
      code    => 'de',
      name    => "German",
      native  => "Deutsch",
      index   => 2,
      sort    => 3,
      rtl     => 0
    },

    {
      code    => 'fr',
      name    => "French",
      native  => "Français",
      index   => 3,
      sort    => 4,
      rtl     => 0
    },

    {
      code    => 'es',
      name    => "Spanish",
      native  => "Español",
      index   => 4,
      sort    => 5,
      rtl     => 0
    },

    {
      code    => 'ja',
      name    => "Japanese",
      native  => "日本",
      index   => 5,
      sort    => 0,
      rtl     => 0
    },

    {
      code    => 'pt',
      name    => "Portuguese",
      native  => "Português",
      index   => 6,
      sort    => 0,
      rtl     => 0
    },

    {
      code    => 'ru',
      name    => "Russian",
      native  => "Русский",
      index   => 7,
      sort    => 2,
      rtl     => 0
    },

    {
      code    => 'tr',
      name    => "Turkish",
      native  => "Türk",
      index   => 8,
      sort    => 6,
      rtl     => 0
    },

    {
      code    => 'zh',
      name    => "Chinese",
      native  => "中国",
      index   => 9,
      sort    => 7,
      rtl     => 0
    }
  )});

  #
  # Helpers
  #

  $app->helper(default_language => sub { shift->languages('en') });

  $app->helper(languages_active => sub {
    my ($c) = @_;

    my $active = $app->languages->grep(sub { $_->{sort} });
    $active->sort(sub { $a->{sort} <=> $b->{sort} });
  });

  $app->helper(language => sub {
    my ($c, $code) = @_;

    $app->languages->grep(sub { lc $code eq lc $_->{code} })->first;
  });

  $app->helper(langs => sub {
    my ($c) = @_;

    $app->languages_active->map(sub { $_->{code} })->flatten->to_array;
  });

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
}

1;
