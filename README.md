# SmppBenchmarks

Can be run as:

```
mix run benchmarks/sync.exs 33333 100000

mix run benchmarks/async.exs 33333 100000 100

mix run benchmarks/oserl_sync.exs 33333 100000

mix run benchmarks/oserl_async.exs 33333 100000 100
```

Results of these benchmarks on my laptop (2,6 GHz Intel Core i7, Erlang 20.3.4, Elixir 1.6.4).

SMPPEX, sync
```
[info]  Starting MC on port 33333
[info]  Starting synchronous ESME
[info]  Sending 100000 PDUs...
[info]  Completed in 13886ms with avg rate 7201.497911565606 pdu/s
```

SMPPEX, async, window 100
```
[info]  Starting MC on port 33333
[info]  Starting ESME with window 100
[info]  Sending 100000 PDUs...
[info]  Completed in 3292ms with avg rate 30376.670716889428 pdu/s
```

Oserl, sync
```
[info]  Starting MC on port 33333
[info]  Starting synchronous ESME
[info]  Sending 100000 PDUs...
[info]  Completed in 16054ms with avg rate 6228.977201943441 pdu/s
```

Oserl, async
```
[info]  Starting MC on port 33333
[info]  Starting ESME with window 100
[info]  Sending 100000 PDUs...
[info]  Completed in 4054ms with avg rate 24666.9955599408 pdu/s
```

Summarized in a table, pdu/s through a single session:

|          | Sync             | Async, window 100 |
|----------|-----------------:|------------------:|
|**SMPPEX**|             7201 |             30377 |
|**Oserl** |             6229 |             24667 |
