<script setup lang="ts">
const route = useRoute()
</script>

<template>
  <div class="min-h-screen bg-background">
    <!-- Header -->
    <header class="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div class="container flex h-16 items-center px-4">
        <div class="flex items-center gap-2">
          <Icon name="lucide:layout-dashboard" class="w-6 h-6 text-primary" />
          <h1 class="text-xl font-bold">음하 스튜디오</h1>
        </div>
        
        <nav class="ml-8 flex gap-6">
          <NuxtLink 
            to="/" 
            class="text-sm font-medium transition-colors hover:text-primary"
            :class="route.path === '/' ? 'text-foreground' : 'text-muted-foreground'"
          >
            게시글 관리
          </NuxtLink>
          <NuxtLink 
            to="/editor/new" 
            class="text-sm font-medium transition-colors hover:text-primary"
            :class="route.path.startsWith('/editor/new') ? 'text-foreground' : 'text-muted-foreground'"
          >
            새 글 작성
          </NuxtLink>
        </nav>

        <div class="ml-auto flex items-center gap-4">
          <Button variant="ghost" size="icon" title="알림">
            <Icon name="lucide:bell" class="w-5 h-5" />
          </Button>
          <Button variant="ghost" size="icon" title="설정">
            <Icon name="lucide:settings" class="w-5 h-5" />
          </Button>
          <div class="flex items-center gap-2 pl-4 border-l">
            <img 
              src="https://i.pravatar.cc/40?u=admin" 
              alt="User avatar"
              class="w-8 h-8 rounded-full"
            />
            <span class="text-sm font-medium">Admin</span>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="container px-4 py-8">
      <slot />
    </main>
  </div>
</template>
