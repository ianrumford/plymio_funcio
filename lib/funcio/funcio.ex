defmodule Plymio.Funcio do
  @moduledoc ~S"""
  `Plymio.Funcio` is a collection of functions for various needs,
  especially enumerables, including mapping the elements
  concurrently in separate tasks.

  It was written as a support package for the `Plymio` and `Harnais`
  family of packages but all of the functions are general purpose.

  ## Documentation Terms

  In the documentation below these terms, usually in *italics*, are used to mean the same thing.

  ### *enum*

  An *enum* is an ernumerable e.g. `List`, `Map`, `Stream`, etc.

  ### *opts* and *opzioni*

  An *opts* is a `Keyword` list. An *opzioni* is a list of *opts*.

  ### *map/1*

  A *map/1* is *zero, one or more* arity 1 functions.

  Multiple functions are usually reduced (by `Plymio.Funcio.Map.Utility.reduce_map1_funs/1`)
  to create a composite function that runs the individual functions in an
  pipeline e.g.

       fn v -> funs |> Enum.reduce(v, fn f,v -> f.(v) end) end

  ### *index map/1*

  An *index map/1* is really the same as *map/1* but it is expected
  that the *first/only* function will be called with `{value, index}`.

  ### *predicate/1*

  A *predicate/1* is *one or more* arity 1 functions that each return either `true` or `false`.

  Multiple predicates are `AND`-ed together by
  `Plymio.Funcio.Predicate.reduce_and_predicate1_funs/1` to create a composite
  predicate e.g.

       fn v -> funs |> Enum.all?(fn f -> f.(v) end) end

  ### *index tuple predicate/1*

  A *index tuple predicate/1* is the same as *predicate/1* but it is
  expected the predeicate will be called with `{value, index}`.

  ## Standard Processing and Result Patterns

  Many functions return either `{:ok, any}` or `{:error, error}`
  where `error` will be an `Exception`.

  Peer bang functions return either `value` or raises `error`.

  There are three common function *patterns* described in
  `Plymio.Fontais`; many of the functions in this package implement
  those patterns.

  ## Streams Enumerables

  Some functions return `{:ok, enum}` where `enum` *may* be a
  `Stream`.  A `Stream` will cause an `Exception` when used / realised
  (e.g. in `Enum.to_list/1`) if the original *enum* was invalid.

  """

  use Plymio.Fontais.Attribute

  @type index :: integer
  @type indices :: [index]
  @type key :: atom
  @type keys :: [key]
  @type error :: struct
  @type stream :: %Stream{}
  @type result :: Plymio.Fontais.result()
  @type opts :: Plymio.Fontais.opts()
  @type opzioni :: Plymio.Fontais.opzioni()
  @type fun1_map :: (any -> any)
  @type fun1_predicate :: (any -> boolean)
end
