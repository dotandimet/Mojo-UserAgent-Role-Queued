requires 'perl', '5.010';
requires 'Mojolicious', '8.03';
requires 'Role::Tiny', '2.000001';
requires 'Class::Method::Modifiers', '2.12';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'configure' => sub {
    requires 'Module::Build::Tiny' , '0.035';
}
