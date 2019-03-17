package Mojolicious::Plugin::AcceptLanguage;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::Collection 'c';
use HTTP::AcceptLanguage;

our $VERSION = "1.01";
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
      place   => 1,
      sort    => 1,
      rtl     => 0
    },

    {
      code    => 'de',
      name    => "German",
      native  => "Deutsch",
      place   => 2,
      sort    => 3,
      rtl     => 0
    },

    {
      code    => 'fr',
      name    => "French",
      native  => "Français",
      place   => 3,
      sort    => 4,
      rtl     => 0
    },

    {
      code    => 'es',
      name    => "Spanish",
      native  => "Español",
      place   => 4,
      sort    => 5,
      rtl     => 0
    },

    {
      code    => 'ja',
      name    => "Japanese",
      native  => "日本",
      place   => 5,
      sort    => 0,
      rtl     => 0
    },

    {
      code    => 'pt',
      name    => "Portuguese",
      native  => "Português",
      place   => 6,
      sort    => 0,
      rtl     => 0
    },

    {
      code    => 'ru',
      name    => "Russian",
      native  => "Русский",
      place   => 7,
      sort    => 2,
      rtl     => 0
    },

    {
      code    => 'tr',
      name    => "Turkish",
      native  => "Türk",
      place   => 8,
      sort    => 6,
      rtl     => 0
    },

    {
      code    => 'zh',
      name    => "Chinese",
      native  => "中国",
      place   => 9,
      sort    => 7,
      rtl     => 0
    }
  )});

  #
  # Helpers
  #

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

  #
  # Hooks
  #

  $app->hook(before_routes => sub {
    my ($c) = @_;

    # Skip CORS preflight requests
    return if $c->req->method eq 'OPTIONS';

    my $header = $c->req->headers->accept_language;
    my $accept_language = HTTP::AcceptLanguage->new($header);

    my $code = $accept_language->match(@{$app->langs});
    return $c->reply->not_acceptable unless $code;

    my $lang = $app->language($code);
    return $c->reply->not_acceptable unless $lang;

    $c->app->log->debug("Accept Language '$lang->{code}'");

    $c->res->headers->append("Vary" => "Accept-Language");
    $c->res->headers->content_language($code);

    $c->stash(language => $lang);
  });
}

1;
