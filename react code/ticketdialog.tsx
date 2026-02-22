{/* Create Ticket Button */}
{permissions.canCreateTickets && (
    <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
    <DialogTrigger asChild>
      <button className="w-full inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all h-9 px-4 py-2 bg-primary text-primary-foreground hover:bg-primary/90">
        <Plus className="w-4 h-4" />
        {t('createTicket')}
      </button>
    </DialogTrigger>
    <DialogContent className="max-w-md">
      <DialogHeader>
        <DialogTitle>Create Support Ticket</DialogTitle>
        <DialogDescription>
          Describe the issue you're experiencing and we'll get back to you soon.
        </DialogDescription>
      </DialogHeader>
      <div className="space-y-4 py-4">
        <div className="space-y-2">
          <Label htmlFor="category">Category</Label>
          <Select
            value={newTicket.category}
            onValueChange={(value) =>
              setNewTicket({ ...newTicket, category: value })
            }
          >
            <SelectTrigger id="category">
              <SelectValue placeholder="Select a category" />
            </SelectTrigger>
            <SelectContent>
              {categories.map((cat) => (
                <SelectItem key={cat} value={cat}>
                  {cat}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label htmlFor="title">Title</Label>
          <Input
            id="title"
            placeholder="Brief description of the issue"
            value={newTicket.title}
            onChange={(e) =>
              setNewTicket({ ...newTicket, title: e.target.value })
            }
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="description">Description</Label>
          <Textarea
            id="description"
            placeholder="Provide more details about the issue..."
            rows={4}
            value={newTicket.description}
            onChange={(e) =>
              setNewTicket({ ...newTicket, description: e.target.value })
            }
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="priority">Priority</Label>
          <Select
            value={newTicket.priority}
            onValueChange={(value) =>
              setNewTicket({ ...newTicket, priority: value })
            }
          >
            <SelectTrigger id="priority">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="low">Low</SelectItem>
              <SelectItem value="medium">Medium</SelectItem>
              <SelectItem value="high">High - Urgent</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <Button variant="outline" className="w-full">
          <ImageIcon className="w-4 h-4 mr-2" />
          Add Photos
        </Button>
      </div>
      <DialogFooter>
        <Button variant="outline" onClick={() => setIsCreateOpen(false)}>
          Cancel
        </Button>
        <Button onClick={handleCreateTicket}>Create Ticket</Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
  )}