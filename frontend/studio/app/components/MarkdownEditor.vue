<script setup lang="ts">
import { ref, watch } from 'vue'

interface MarkdownEditorProps {
  modelValue: string
  placeholder?: string
}

const props = withDefaults(defineProps<MarkdownEditorProps>(), {
  placeholder: 'Write your content in markdown...',
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const localValue = ref(props.modelValue)

watch(() => props.modelValue, (newValue) => {
  localValue.value = newValue
})

watch(localValue, (newValue) => {
  emit('update:modelValue', newValue)
})

const handleInput = (event: Event) => {
  const target = event.target as HTMLTextAreaElement
  localValue.value = target.value
}

const insertMarkdown = (syntax: string) => {
  const textarea = document.querySelector<HTMLTextAreaElement>('.markdown-textarea')
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = localValue.value.substring(start, end)
  
  let newText = ''
  let cursorOffset = 0

  switch (syntax) {
    case 'bold':
      newText = `**${selectedText || 'bold text'}**`
      cursorOffset = selectedText ? newText.length : 2
      break
    case 'italic':
      newText = `*${selectedText || 'italic text'}*`
      cursorOffset = selectedText ? newText.length : 1
      break
    case 'heading':
      newText = `## ${selectedText || 'Heading'}`
      cursorOffset = selectedText ? newText.length : 3
      break
    case 'link':
      newText = `[${selectedText || 'link text'}](url)`
      cursorOffset = selectedText ? selectedText.length + 3 : 1
      break
    case 'code':
      newText = `\`${selectedText || 'code'}\``
      cursorOffset = selectedText ? newText.length : 1
      break
    case 'list':
      newText = `- ${selectedText || 'list item'}`
      cursorOffset = selectedText ? newText.length : 2
      break
  }

  localValue.value = 
    localValue.value.substring(0, start) + 
    newText + 
    localValue.value.substring(end)

  setTimeout(() => {
    textarea.focus()
    textarea.setSelectionRange(start + cursorOffset, start + cursorOffset)
  }, 0)
}
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="flex items-center gap-2 p-2 border-b bg-muted/30">
      <Button 
        variant="ghost" 
        size="sm"
        @click="insertMarkdown('bold')"
        title="Bold"
      >
        <Icon name="lucide:bold" class="w-4 h-4" />
      </Button>
      <Button 
        variant="ghost" 
        size="sm"
        @click="insertMarkdown('italic')"
        title="Italic"
      >
        <Icon name="lucide:italic" class="w-4 h-4" />
      </Button>
      <Button 
        variant="ghost" 
        size="sm"
        @click="insertMarkdown('heading')"
        title="Heading"
      >
        <Icon name="lucide:heading" class="w-4 h-4" />
      </Button>
      <Button 
        variant="ghost" 
        size="sm"
        @click="insertMarkdown('link')"
        title="Link"
      >
        <Icon name="lucide:link" class="w-4 h-4" />
      </Button>
      <Button 
        variant="ghost" 
        size="sm"
        @click="insertMarkdown('code')"
        title="Code"
      >
        <Icon name="lucide:code" class="w-4 h-4" />
      </Button>
      <Button 
        variant="ghost" 
        size="sm"
        @click="insertMarkdown('list')"
        title="List"
      >
        <Icon name="lucide:list" class="w-4 h-4" />
      </Button>
    </div>
    
    <textarea
      :value="localValue"
      @input="handleInput"
      :placeholder="placeholder"
      class="markdown-textarea flex-1 w-full p-4 bg-background text-foreground border-0 outline-hidden resize-none font-mono text-sm"
    />
  </div>
</template>
