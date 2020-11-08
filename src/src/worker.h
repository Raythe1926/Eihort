/* Copyright (c) 2012, Jason Lloyd-Price
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#ifndef WORKER_H
#define WORKER_H

#include <list>
#include <SDL_mutex.h>
#include <SDL_thread.h>

namespace eihort {

class Worker {
	// Represents a worker thread that can be assigned work
	// Should be created with new; cleans itself up when killed

public:
	Worker();

	typedef void (*Executor)( void* cookie );

	// Queue a task for execution
	void doTask( Executor exec, void *cookie );
	// Kill the worker thread after it completes its tasks
	void killWorker();

private:
	~Worker();

	// Entrypoint for the worker thread
	static int workerFunc( void *worker );
	// Task which will kill this worker thread
	static void killMe( void *worker );

	struct Task {
		// Function to execute to perform this task
		Executor exec;
		// Opaque cookie passed to the executor
		void *cookie;
	};
	// Task queue
	std::list<Task> queue;

	// The worker thread
	SDL_Thread *thread;
	// Semaphore indicating how much work there is in the queue
	SDL_sem *workToDo;
	// Mutex protecting access to the queue
	SDL_mutex *queueLock;
	// Termination flag
	bool endWorker;
};

} // namespace

#endif
