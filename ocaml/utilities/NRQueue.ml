open Grammar_types

module type QUEUE_ELEMENT_TYPE =
  sig
    type t
    val equals: t -> t -> bool
  end

module NRQueue =
  functor (Queue_element: QUEUE_ELEMENT_TYPE) ->
    struct
      exception Empty_queue
      type element = Queue_element.t
      let equals = Queue_element.equals
      let empty = []
      let length queue = List.length queue
      let is_empty queue =
        match queue with
        | [] -> true
        | _ -> false
      let element_exists queue element =
        List.exists
          (equals element)
          queue
      let enqueue queue element =
        if
          element_exists queue element
        then
          queue
        else
          queue@[element]
            
      let head queue =
        match queue with
        | [] -> raise Empty_queue
        | hd::tl -> hd

      let dequeue queue =
        match queue with
        | [] -> raise Empty_queue
        | hd::tl -> (hd, tl)
          
    end

module PCQueueElement =
  struct
    type t = {parent: int option; edge: transition option; child: int}
    let equals e1 e2 = (e1.child = e2.child)
  end

module PCQueue = NRQueue(PCQueueElement)
