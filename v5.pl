%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Servidor em prolog

% Módulos:
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/json)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json_convert)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_dirindex)).
%DEBUG:
:- use_module(library(http/http_error)).
:- debug.

% GET
:- http_handler(
    root(action), % Alias /action
    action,       % Predicado 'action'
    []).

:- http_handler(root(.), http_reply_from_files('.', []), [prefix]).

:- json_object
    controles(forward:integer, reverse: integer, left:integer, right:integer).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]).

stop_server(Port) :-
    http_stop_server(Port, []).

action(Request) :-
    http_parameters(Request,
                    % sensores do carro:
                    [ x(X, [float]),
                      y(Y, [float]),
                      angle(ANGLE, [float]),
                      s1(S1, [float]),
                      s2(S2, [float]),
                      s3(S3, [float]),
                      s4(S4, [float]),
                      s5(S5, [float])
                    ]),
    SENSORES = [X,Y,ANGLE,S1,S2,S3,S4,S5],
    obter_controles(SENSORES, CONTROLES),
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT],
    prolog_to_json( controles(FORWARD, REVERSE, LEFT, RIGHT), JOut ),
    reply_json( JOut ).

start :- format('~n~n--========================================--~n~n'),
         start_server(8080),
         format('~n~n--========================================--~n~n').
:- initialization start.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%AJUSTANDO ÂNGULO: SENTIDO HORÁRIO (Prioridade Máxima)
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0]) :-
    ANGLE < -1.

%AJUSTANDO ÂNGULO: SENTIDO ANTI-HORÁRIO (Prioridade Máxima)
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1]) :-
    ANGLE > 1.

%SE LIVRAR DE UM CARRO MUITO PRÓXIMO À DIREITA (Prioridade Grande)
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0]) :-
    S5 > 0.75.

%SE LIVRAR DE UM CARRO MUITO PRÓXIMO À ESQUERDA (Prioridade Grande)
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1]) :-
    S1 > 0.75.

%FRENTE, ENQUANTO O ÂNGULO ESTIVER PRÓXIMO DE 0 E NÃO HOUVER NENHUM OBSTÁCULO CRÍTICO À FRENTE
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,0]) :-
    S2 < 0.7,
    S3 < 0.5,
    S4 < 0.7,
    ANGLE > -0.5,
    ANGLE < 0.5.
    /*
    Também serve para que, assim que aparecer um obstáculo à frente, ele pare de andar somente pra frente, e sim
    desvie para a esquerda ou direita, de acordo com as regras posteriores. Desviando do obstáculo.

    Essa regra ter maior prioridade que a FRENTE-ESQUERDA e FRENTE-DIREITA também possibilita que ele ande rente à
    parede.
    */

%FRENTE-ESQUERDA
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,1,0]) :-
    S4+S5 > S1+S2+0.1.

%FRENTE-DIREITA
obter_controles([X,Y,ANGLE,S1,S2,S3,S4,S5], [1,0,0,1]) :-
    S1+S2 > S4+S5+0.1.