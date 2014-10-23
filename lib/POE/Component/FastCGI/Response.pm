=head1 NAME

POE::Component::FastCGI::Response - PoCo::FastCGI HTTP Response class 

=head1 SYNOPSIS

   use POE::Component::FastCGI::Response;
   my $response = POE::Component::FastCGI::Response->new($client, $id,
      200, ..  HTTP::Response parameters ..);

=head1 DESCRIPTION

This module is generally not used directly, you should call
L<POE::Component::FastCGI::Request>'s C<make_response> method which
returns an object of this class.

C<POE::Component::FastCGI::Response> is a subclass of L<HTTP::Response>
so inherits all of its methods. The includes C<header()> for setting output
headers and C<content()> for setting the content.

Therefore the following methods mostly deal with actually sending the
response:

=over 4

=cut

package POE::Component::FastCGI::Response;
use strict;
use base qw/HTTP::Response/;
use bytes;

=item $response = POE::Component::FastCGI::Response->new($client, $id, $code)

Creates a new C<POE::Component::FastCGI::Response> object, parameters from
C<$code> onwards are passed directly to L<HTTP::Response>'s constructor.

=cut
sub new {
   my($class, $client, $id, $code, @response) = @_;
   $code = 200 unless defined $code;

   my $response = $class->SUPER::new($code, @response);

   $response->{client} = $client;
   $response->{requestid} = $id;

   return $response;
}

sub DESTROY {
   my($self) = @_;
   $self->close;
}

=item $response->send

Sends the response object and ends the current connection.

=cut

sub send {
   my($self) = @_;

# Adapted from POE::Filter::HTTPD
   my $status_line = "Status: " . $self->code;

   # Use network newlines, and be sure not to mangle newlines in the
   # response's content.

   my @headers;
   push @headers, $status_line;
   push @headers, $self->headers_as_string("\x0D\x0A");

   $self->{client}->put({
      requestid => $self->{requestid},
      close => 1,
      content => join("\x0D\x0A", @headers, "") . $self->content
   });
   delete $self->{client};
   return 1;
}

=item $response->write($text)

Writes some text directly to the output stream, for use when you don't want
to or can't send a L<HTTP::Response> object.

=cut
sub write {
   my($self, $out) = @_;
   $self->{client}->put({requestid => $self->{requestid}, content => $out});
   return 1;
}

=item $response->close

Closes the output stream.

You don't normally need to use this as the object will automatically close
when DESTROYed.

=cut
sub close {
   my($self, $out) = @_;
   return unless defined $self->{client};
   $self->{client}->put({
      requestid => $self->{requestid},
      close => 1,
      content => ""
   });
   delete $self->{client};
   return 1;
}

=item $response->redirect($url)

Sets the object to be a redirect to $url. You still need to call C<send> to
actually send the redirect.

=cut
sub redirect {
   my($self, $url) = @_;
   $self->code(302);
   $self->header(Location => ($url =~ m!^\w+://! ? $url : "http://"
      . $self->uri->host . ($self->uri->port ? ":" . $self->uri->port : "")
      . "/" . $url));
}

=item $response->error($code, $text)

Sends an error to the client, $code is the HTTP error code and $text is
the content of the page to send.

=cut
sub error {
   my($self, $code, $text) = @_;
   $self->code($code);
   $self->header("Content-type" => "text/html");
   $self->content(defined $text ? $text : $self->error_as_HTML);
   $self->send;
}

1;

=back

=head1 AUTHOR

Copyright 2005, David Leadbeater L<http://dgl.cx/contact>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please let me know.

=head1 SEE ALSO

L<POE::Component::FastCGI::Request>, L<HTTP::Response>, 
L<POE::Component::FastCGI>, L<POE>.

=cut
