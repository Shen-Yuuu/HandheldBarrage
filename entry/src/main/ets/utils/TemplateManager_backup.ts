import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { BarrageConfig } from '../model/BarrageConfig';

const PREF_NAME = 'barrage_templates';

export class TemplateManager {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async getPreferences() {
    return await preferences.getPreferences(this.context, PREF_NAME);
  }

  async saveTemplate(name: string, config: BarrageConfig) {
    const pref = await this.getPreferences();
    // Serialize config to JSON string
    // Note: We need to handle circular references if any, but BarrageConfig is simple data
    const jsonStr = JSON.stringify(config);
    await pref.put(name, jsonStr);
    await pref.flush();
  }

  async loadTemplate(name: string): Promise<BarrageConfig | null> {
    const pref = await this.getPreferences();
    const jsonStr = await pref.get(name, '') as string;
    if (!jsonStr) return null;
    try {
      const rawObj = JSON.parse(jsonStr);
      // Reconstruct object to ensure methods/prototypes if needed (though BarrageConfig is mostly data)
      // For simplicity, we assign properties. In a real app, we might use a mapper.
      const config = new BarrageConfig();
      Object.assign(config, rawObj);
      return config;
    } catch (e) {
      console.error('Failed to parse template', e);
      return null;
    }
  }

  async getAllTemplates(): Promise<string[]> {
    const pref = await this.getPreferences();
    const all = await pref.getAll();
    return Object.keys(all);
  }

  async deleteTemplate(name: string) {
    const pref = await this.getPreferences();
    await pref.delete(name);
    await pref.flush();
  }
}